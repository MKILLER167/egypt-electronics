import requests
from bs4 import BeautifulSoup
import pandas as pd
import os
import time
import logging
from urllib.parse import urljoin, urlparse
import re
from datetime import datetime

class RealImageScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        self.data_dir = os.path.join(os.path.dirname(__file__), 'data')
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Real Egyptian electronics store URLs
        self.stores = {
            'microohm': {
                'name': 'Microohm',
                'base_url': 'https://microohm-eg.com',
                'csv_file': 'microohm_products.csv'
            },
            'electrohub': {
                'name': 'ElectroHub',
                'base_url': 'https://electrohub.com.eg',
                'csv_file': 'electrohub_products.csv'
            },
            'ekostra': {
                'name': 'Ekostra',
                'base_url': 'https://ekostra.com',
                'csv_file': 'ekostra_products.csv'
            },
            'ram': {
                'name': 'RAM Electronics',
                'base_url': 'https://ram-e-shop.com',
                'csv_file': 'ram_products.csv'
            }
        }
    
    def get_real_product_images(self, store_key):
        """Get real product images from store website"""
        try:
            url = self.stores[store_key]['base_url']
            response = self.session.get(url, timeout=10)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find all product images
            images = []
            img_elements = soup.find_all('img')
            
            for i, img in enumerate(img_elements[:100]):  # Get first 100 images
                try:
                    src = img.get('src') or img.get('data-src') or img.get('data-lazy')
                    if src:
                        if not src.startswith('http'):
                            src = urljoin(url, src)
                        
                        # Filter out non-product images
                        if any(keyword in src.lower() for keyword in ['product', 'item', 'thumb', 'photo', 'image']):
                            # Get alt text for description
                            alt_text = img.get('alt', f'Product {i+1}')
                            
                            images.append({
                                'url': src,
                                'alt': alt_text,
                                'index': i + 1
                            })
                except Exception as e:
                    logging.warning(f"Error processing image {i}: {e}")
                    continue
            
            logging.info(f"Found {len(images)} real product images for {store_key}")
            return images
            
        except Exception as e:
            logging.error(f"Error getting images from {store_key}: {e}")
            return []
    
    def update_csv_with_real_images(self, store_key):
        """Update existing CSV with real images and links"""
        csv_path = os.path.join(self.data_dir, self.stores[store_key]['csv_file'])
        
        if not os.path.exists(csv_path):
            logging.error(f"CSV file not found: {csv_path}")
            return False
        
        try:
            # Load existing products
            df = pd.read_csv(csv_path)
            
            # Get real images from website
            real_images = self.get_real_product_images(store_key)
            
            # Update products with real images
            updated_products = []
            
            for i, row in df.iterrows():
                product = row.to_dict()
                
                # Use real image if available, otherwise keep existing
                if i < len(real_images):
                    real_img = real_images[i]
                    product['image'] = real_img['url']
                    product['description'] = f"Real product image: {real_img['alt']}"
                
                # Update link to real product page
                base_url = self.stores[store_key]['base_url']
                product['link'] = f"{base_url}/product/{product['id']}"
                
                updated_products.append(product)
            
            # Save updated CSV
            updated_df = pd.DataFrame(updated_products)
            updated_df.to_csv(csv_path, index=False)
            
            logging.info(f"Updated {len(updated_products)} products with real images for {store_key}")
            return True
            
        except Exception as e:
            logging.error(f"Error updating CSV for {store_key}: {e}")
            return False
    
    def create_real_image_gallery(self, store_key):
        """Create a gallery of real product images"""
        try:
            images = self.get_real_product_images(store_key)
            
            # Create HTML gallery
            gallery_html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>{self.stores[store_key]['name']} Product Gallery</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .gallery {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px; }}
        .product {{ border: 1px solid #ddd; padding: 10px; text-align: center; }}
        .product img {{ max-width: 100%; height: 150px; object-fit: cover; }}
        .product-info {{ margin-top: 10px; }}
        h1 {{ color: #333; }}
    </style>
</head>
<body>
    <h1>{self.stores[store_key]['name']} Real Product Images</h1>
    <div class="gallery">
"""
            
            for img in images[:50]:  # Show first 50 images
                gallery_html += f"""
        <div class="product">
            <img src="{img['url']}" alt="{img['alt']}" onerror="this.src='https://images.unsplash.com/photo-1553406830-ef2513450d76?w=200&h=150&fit=crop'">
            <div class="product-info">
                <p>{img['alt']}</p>
                <small>Image {img['index']}</small>
            </div>
        </div>
"""
            
            gallery_html += """
    </div>
</body>
</html>
"""
            
            # Save gallery
            gallery_path = os.path.join(self.data_dir, f'{store_key}_gallery.html')
            with open(gallery_path, 'w', encoding='utf-8') as f:
                f.write(gallery_html)
            
            logging.info(f"Created image gallery: {gallery_path}")
            return gallery_path
            
        except Exception as e:
            logging.error(f"Error creating gallery for {store_key}: {e}")
            return None
    
    def update_all_stores(self):
        """Update all stores with real images"""
        results = {}
        
        for store_key in self.stores.keys():
            logging.info(f"Updating {store_key} with real images...")
            
            # Update CSV with real images
            success = self.update_csv_with_real_images(store_key)
            
            # Create image gallery
            gallery_path = self.create_real_image_gallery(store_key)
            
            results[store_key] = {
                'csv_updated': success,
                'gallery_created': gallery_path is not None,
                'gallery_path': gallery_path
            }
            
            # Add delay between stores
            time.sleep(2)
        
        return results

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message}s')
    
    scraper = RealImageScraper()
    results = scraper.update_all_stores()
    
    print("\nREAL IMAGE UPDATE RESULTS")
    print("=" * 50)
    
    for store_key, result in results.items():
        print(f"\n{store_key.upper()}:")
        print(f"  CSV Updated: {'Yes' if result['csv_updated'] else 'No'}")
        print(f"  Gallery Created: {'Yes' if result['gallery_created'] else 'No'}")
        if result['gallery_path']:
            print(f"  Gallery: {result['gallery_path']}")
    
    print(f"\nOpen the HTML files in your browser to view real product images!")
