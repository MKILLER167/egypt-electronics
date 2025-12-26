import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
from urllib.parse import urljoin
import logging

class RamScraper:
    def __init__(self):
        self.base_url = "https://www.ram-e-shop.com"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        self.products = []
        
    def get_category_urls(self):
        """Get main category URLs from the homepage"""
        try:
            response = self.session.get(self.base_url)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
            categories = []
            # Look for navigation menu items and category links
            nav_items = soup.find_all('a', href=True)
            for item in nav_items:
                href = item.get('href')
                text = item.get_text(strip=True).lower()
                if href and any(keyword in text for keyword in ['shop', 'product', 'category', 'electronics']):
                    # Fix URL joining - avoid double URLs
                    if href.startswith('http'):
                        full_url = href
                    else:
                        full_url = urljoin(self.base_url, href)
                    categories.append(full_url)
            
            # Add common shop paths
            common_paths = ['/shop', '/products', '/category']
            for path in common_paths:
                full_url = urljoin(self.base_url, path)
                categories.append(full_url)
            
            return list(set(categories))  # Remove duplicates
        except Exception as e:
            logging.error(f"Error getting categories: {e}")
            return [self.base_url]  # Fallback to main page
    
    def scrape_category(self, category_url):
        """Scrape products from a category page"""
        try:
            response = self.session.get(category_url)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
            products = []
            
            # Try multiple selectors for product containers
            product_selectors = [
                'div.product',
                'div.product-item',
                'div.item',
                'article.product',
                'div.woocommerce-product',
                'li.product',
                'div.col-item',
                '[class*="product"]',
                '[class*="item"]',
                '.product-wrapper',
                '.item-wrapper'
            ]
            
            product_elements = []
            for selector in product_selectors:
                elements = soup.select(selector)
                if elements:
                    product_elements.extend(elements)
                    logging.info(f"Found {len(elements)} products with selector: {selector}")
            
            # If no specific selectors work, try broader approach
            if not product_elements:
                # Look for any div containing price and name patterns
                all_divs = soup.find_all('div')
                for div in all_divs:
                    # Check if div contains both a price and a link/image
                    text_content = div.get_text()
                    has_price = any(symbol in text_content for symbol in ['EGP', '£', '$', '€']) and any(char.isdigit() for char in text_content)
                    has_link = div.find('a')
                    has_image = div.find('img')
                    
                    if has_price and (has_link or has_image):
                        product_elements.append(div)
            
            logging.info(f"Total product elements found: {len(product_elements)}")
            
            for element in product_elements:
                product = self.extract_product_info(element)
                if product:
                    products.append(product)
            
            return products
        except Exception as e:
            logging.error(f"Error scraping category {category_url}: {e}")
            return []
    
    def extract_product_info(self, element):
        """Extract product information from a product element"""
        try:
            # Product name - try multiple selectors
            name_selectors = ['h2.product-title', 'h3.name', 'h4.title', '.product-name', 'a.product-link', 'h2', 'h3', 'h4']
            name = "Unknown Product"
            for selector in name_selectors:
                name_elem = element.select_one(selector)
                if name_elem:
                    name = name_elem.get_text(strip=True)
                    break
            
            # Price - try multiple selectors with better EGP detection
            price_selectors = ['.price', '.product-price', '.cost', '.amount', '.value', '.price-current']
            price_text = "0"
            for selector in price_selectors:
                price_elem = element.select_one(selector)
                if price_elem:
                    price_text = price_elem.get_text(strip=True)
                    break
            
            # If no specific price element, look for any text with EGP
            if price_text == "0":
                text_content = element.get_text()
                for text in text_content.split():
                    if 'EGP' in text and any(char.isdigit() for char in text):
                        price_text = text
                        break
            
            price = self.clean_price(price_text)
            
            # Product URL
            link_elem = element.find('a', href=True)
            product_url = urljoin(self.base_url, link_elem.get('href')) if link_elem else ""
            
            # Image URL
            img_elem = element.find('img')
            image_url = urljoin(self.base_url, img_elem.get('src')) if img_elem else ""
            
            # Availability
            availability_elem = element.select_one('.stock, .availability, .in-stock')
            availability = availability_elem.get_text(strip=True) if availability_elem else "In Stock"
            
            # Brand/Category
            brand_elem = element.select_one('.brand, .category, .manufacturer')
            brand = brand_elem.get_text(strip=True) if brand_elem else ""
            
            # Specifications
            spec_elem = element.select_one('.specs, .specifications, .features')
            specifications = spec_elem.get_text(strip=True) if spec_elem else ""
            
            # Stock status
            stock_elem = element.select_one('.stock-status, .availability')
            stock_status = stock_elem.get_text(strip=True) if stock_elem else ""
            
            return {
                'name': name,
                'price': price,
                'price_text': price_text,
                'url': product_url,
                'image_url': image_url,
                'availability': availability,
                'brand': brand,
                'specifications': specifications,
                'stock_status': stock_status,
                'store': 'RAM',
                'scraped_at': pd.Timestamp.now()
            }
        except Exception as e:
            logging.error(f"Error extracting product info: {e}")
            return None
    
    def clean_price(self, price_text):
        """Clean and convert price text to numeric value"""
        try:
            # Remove currency symbols and whitespace
            clean_text = ''.join(c for c in price_text if c.isdigit() or c == '.' or c == ',')
            # Replace comma with dot for decimal
            clean_text = clean_text.replace(',', '.')
            return float(clean_text) if clean_text else 0.0
        except:
            return 0.0
    
    def scrape_all(self):
        """Main scraping method"""
        logging.info("Starting RAM scraper")
        
        categories = self.get_category_urls()
        
        for category_url in categories:
            logging.info(f"Scraping category: {category_url}")
            products = self.scrape_category(category_url)
            self.products.extend(products)
            time.sleep(2)  # Be respectful to the server
        
        logging.info(f"Scraped {len(self.products)} products from RAM")
        return self.products

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    scraper = RamScraper()
    products = scraper.scrape_all()
    
    if products:
        df = pd.DataFrame(products)
        df.to_csv('../data/ram_products.csv', index=False)
        print(f"Saved {len(products)} products to ram_products.csv")
    else:
        print("No products found")
