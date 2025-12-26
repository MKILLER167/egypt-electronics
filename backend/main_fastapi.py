from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import threading

# Add the scraper directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'scrapers'))

app = FastAPI(title="Egypt Electronics API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class Product(BaseModel):
    id: int
    name: str
    price: float
    image: str
    brand: str
    category: str
    store: str
    availability: str
    rating: float

class ScrapeStatus(BaseModel):
    status: str
    message: str
    products_count: int = 0

# In-memory storage
products_db: List[Product] = []
scraping_status = {"status": "idle", "message": "", "products_count": 0}

# Import and initialize scrapers
def get_scrapers():
    scrapers = []
    try:
        from microohm_fixed import MicroohmScraper
        scrapers.append(("Microohm", MicroohmScraper()))
    except ImportError:
        print("Microohm scraper not available")
    
    try:
        from electrohub_fixed import ElectrohubScraper
        scrapers.append(("ElectroHub", ElectrohubScraper()))
    except ImportError:
        print("ElectroHub scraper not available")
    
    try:
        from ekostra_fixed import EkostraScraper
        scrapers.append(("Ekostra", EkostraScraper()))
    except ImportError:
        print("Ekostra scraper not available")
    
    try:
        from ram_fixed import RamScraper
        scrapers.append(("RAM", RamScraper()))
    except ImportError:
        print("RAM scraper not available")
    
    return scrapers

@app.get("/")
async def root():
    return {"message": "Egypt Electronics API"}

@app.get("/api/products", response_model=List[Product])
async def get_products():
    """Get all products"""
    return products_db

@app.get("/api/stats")
async def get_stats():
    """Get statistics"""
    if not products_db:
        return {
            "total_products": 0,
            "total_stores": 0,
            "avg_price": 0,
            "lowest_price": 0
        }
    
    stores = list(set(p.store for p in products_db))
    avg_price = sum(p.price for p in products_db) / len(products_db)
    lowest_price = min(p.price for p in products_db)
    
    return {
        "total_products": len(products_db),
        "total_stores": len(stores),
        "avg_price": round(avg_price, 2),
        "lowest_price": lowest_price
    }

@app.post("/api/scrape", response_model=ScrapeStatus)
async def start_scraping():
    """Start scraping all stores"""
    global scraping_status, products_db
    
    if scraping_status["status"] == "running":
        return ScrapeStatus(
            status="running",
            message="Scraping already in progress",
            products_count=len(products_db)
        )
    
    scraping_status = {
        "status": "running",
        "message": "Starting scraping...",
        "products_count": len(products_db)
    }
    
    # Run scraping in background
    def scrape_all():
        global products_db, scraping_status
        try:
            all_products = []
            scrapers = get_scrapers()
            
            if not scrapers:
                print("No scrapers available")
                scraping_status = {
                    "status": "error",
                    "message": "No scrapers available - check scraper imports",
                    "products_count": 0
                }
                return
            
            with ThreadPoolExecutor(max_workers=4) as executor:
                future_to_store = {
                    executor.submit(scraper.scrape_all): store 
                    for store, scraper in scrapers
                }
                
                for future in as_completed(future_to_store):
                    store = future_to_store[future]
                    try:
                        scraped_products = future.result()
                        print(f"Scraped {len(scraped_products)} products from {store}")
                        if scraped_products:
                            for product in scraped_products:
                                # Handle different scraper output formats
                                if isinstance(product, dict):
                                    product_dict = {
                                        "id": len(all_products) + 1,
                                        "name": product.get("name", "Unknown Product"),
                                        "price": float(product.get("price", 0)),
                                        "image": product.get("image", ""),
                                        "brand": product.get("brand", "Unknown"),
                                        "category": product.get("category", "Electronics"),
                                        "store": store,
                                        "availability": product.get("availability", "In Stock"),
                                        "rating": float(product.get("rating", 4.5))
                                    }
                                else:
                                    # Handle object format
                                    product_dict = {
                                        "id": len(all_products) + 1,
                                        "name": getattr(product, "name", "Unknown Product"),
                                        "price": float(getattr(product, "price", 0)),
                                        "image": getattr(product, "image", ""),
                                        "brand": getattr(product, "brand", "Unknown"),
                                        "category": getattr(product, "category", "Electronics"),
                                        "store": store,
                                        "availability": getattr(product, "availability", "In Stock"),
                                        "rating": float(getattr(product, "rating", 4.5))
                                    }
                                all_products.append(Product(**product_dict))
                    except Exception as e:
                        print(f"Error scraping {store}: {e}")
            
            if all_products:
                products_db = all_products
                scraping_status = {
                    "status": "completed",
                    "message": f"Successfully scraped {len(all_products)} products",
                    "products_count": len(all_products)
                }
            else:
                scraping_status = {
                    "status": "completed",
                    "message": "No products found from scrapers",
                    "products_count": 0
                }
        except Exception as e:
            scraping_status = {
                "status": "error",
                "message": f"Scraping failed: {str(e)}",
                "products_count": len(products_db)
            }
    
    # Start background scraping
    threading.Thread(target=scrape_all).start()
    
    return ScrapeStatus(
        status="running",
        message="Scraping started...",
        products_count=len(products_db)
    )

@app.post("/api/products/add-sample")
async def add_sample_data():
    """Add sample products for testing"""
    global products_db
    
    sample_products = [
        Product(
            id=1,
            name="ESP32-CAM + ESP32-CAM-MB – 2MP OV2640, USB Programmer, microSD",
            price=165.0,
            image="https://images.unsplash.com/photo-1608564697071-ddf911d81370?w=300&h=300&fit=crop",
            brand="Espressif",
            category="Wireless Modules",
            store="Microohm",
            availability="In Stock",
            rating=4.7
        ),
        Product(
            id=2,
            name="Arduino Uno R3 Development Board",
            price=450.0,
            image="https://images.unsplash.com/photo-1553406830-ef2513450d76?w=300&h=300&fit=crop",
            brand="Arduino",
            category="Development Boards",
            store="Microohm",
            availability="In Stock",
            rating=4.8
        ),
        Product(
            id=3,
            name="Raspberry Pi 4 Model B 4GB RAM",
            price=1250.0,
            image="https://images.unsplash.com/photo-1559163499-413811fb2344?w=300&h=300&fit=crop",
            brand="Raspberry Pi",
            category="Single Board Computers",
            store="ElectroHub",
            availability="In Stock",
            rating=4.9
        ),
        Product(
            id=4,
            name="ESP32 DevKit V1 WiFi Bluetooth Module",
            price=85.0,
            image="https://images.unsplash.com/photo-1608564697071-ddf911d81370?w=300&h=300&fit=crop",
            brand="Espressif",
            category="Wireless Modules",
            store="Ekostra",
            availability="In Stock",
            rating=4.6
        ),
        Product(
            id=5,
            name="Digital Multimeter Professional Grade",
            price=120.0,
            image="https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=300&h=300&fit=crop",
            brand="Generic",
            category="Test Equipment",
            store="RAM",
            availability="In Stock",
            rating=4.5
        )
    ]
    
    products_db = sample_products
    return {"message": f"Added {len(sample_products)} sample products"}

@app.get("/api/scrape/status", response_model=ScrapeStatus)
async def get_scrape_status():
    """Get current scraping status"""
    return ScrapeStatus(**scraping_status)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
