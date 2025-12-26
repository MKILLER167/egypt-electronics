from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import pandas as pd
import os
from datetime import datetime

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

# CSV file path
CSV_FILE = os.path.join(os.path.dirname(__file__), 'products.csv')

def load_products_from_csv():
    """Load products from CSV file"""
    try:
        if not os.path.exists(CSV_FILE):
            return []
        
        df = pd.read_csv(CSV_FILE)
        products = []
        
        for idx, row in df.iterrows():
            product = Product(
                id=idx + 1,
                name=str(row['name']),
                price=float(row['price']),
                image=str(row['image']),
                brand=str(row['brand']),
                category=str(row['category']),
                store=str(row['store']),
                availability=str(row['availability']),
                rating=float(row['rating'])
            )
            products.append(product)
        
        return products
    except Exception as e:
        print(f"Error loading CSV: {e}")
        return []

def save_products_to_csv(products: List[Product]):
    """Save products to CSV file"""
    try:
        data = []
        for product in products:
            data.append({
                'name': product.name,
                'price': product.price,
                'image': product.image,
                'brand': product.brand,
                'category': product.category,
                'store': product.store,
                'availability': product.availability,
                'rating': product.rating
            })
        
        df = pd.DataFrame(data)
        df.to_csv(CSV_FILE, index=False)
        return True
    except Exception as e:
        print(f"Error saving CSV: {e}")
        return False

# Load products on startup
products_db = load_products_from_csv()
print(f"Loaded {len(products_db)} products from CSV")

@app.get("/")
async def root():
    return {
        "message": "Egypt Electronics API",
        "products_count": len(products_db),
        "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

@app.get("/api/products", response_model=List[Product])
async def get_products():
    """Get all products from CSV"""
    global products_db
    products_db = load_products_from_csv()
    return products_db

@app.get("/api/stats")
async def get_stats():
    """Get statistics"""
    global products_db
    products_db = load_products_from_csv()
    
    if not products_db:
        return {
            "total_products": 0,
            "total_stores": 0,
            "avg_price": 0,
            "lowest_price": 0,
            "highest_price": 0
        }
    
    stores = list(set(p.store for p in products_db))
    prices = [p.price for p in products_db if p.price > 0]
    
    return {
        "total_products": len(products_db),
        "total_stores": len(stores),
        "avg_price": round(sum(prices) / len(prices), 2) if prices else 0,
        "lowest_price": min(prices) if prices else 0,
        "highest_price": max(prices) if prices else 0
    }

@app.post("/api/scrape", response_model=ScrapeStatus)
async def simulate_scraping():
    """Simulate scraping and update CSV with new data"""
    global products_db
    
    # Simulate finding new products
    import random
    
    new_products = [
        Product(
            id=len(products_db) + 1,
            name=f"New Product {len(products_db) + 1}",
            price=random.uniform(50, 500),
            image="https://images.unsplash.com/photo-1608564697071-ddf911d81370?w=300&h=300&fit=crop",
            brand=random.choice(["Arduino", "Espressif", "Raspberry Pi", "Generic"]),
            category=random.choice(["Development Boards", "Wireless Modules", "Components", "Tools"]),
            store=random.choice(["Microohm", "ElectroHub", "Ekostra", "RAM"]),
            availability="In Stock",
            rating=round(random.uniform(4.0, 5.0), 1)
        )
    ]
    
    # Add new products to existing
    all_products = products_db + new_products
    
    # Save to CSV
    if save_products_to_csv(all_products):
        products_db = all_products
        return ScrapeStatus(
            status="completed",
            message=f"Added {len(new_products)} new products to CSV",
            products_count=len(products_db)
        )
    else:
        return ScrapeStatus(
            status="error",
            message="Failed to save products to CSV",
            products_count=len(products_db)
        )

@app.post("/api/products/add-sample")
async def add_sample_data():
    """Add sample data to CSV"""
    global products_db
    
    sample_products = [
        Product(
            id=1,
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
            id=2,
            name="ESP32-CAM + ESP32-CAM-MB – 2MP OV2640",
            price=165.0,
            image="https://images.unsplash.com/photo-1608564697071-ddf911d81370?w=300&h=300&fit=crop",
            brand="Espressif",
            category="Wireless Modules",
            store="Microohm",
            availability="In Stock",
            rating=4.7
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
        )
    ]
    
    if save_products_to_csv(sample_products):
        products_db = sample_products
        return {"message": f"Added {len(sample_products)} sample products to CSV"}
    else:
        return {"message": "Failed to save sample products"}

@app.get("/api/scrape/status", response_model=ScrapeStatus)
async def get_scrape_status():
    """Get current scraping status"""
    return ScrapeStatus(
        status="idle",
        message="CSV-based system ready",
        products_count=len(products_db)
    )

if __name__ == "__main__":
    import uvicorn
    print("Starting Egypt Electronics API with CSV storage...")
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
