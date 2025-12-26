from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
import pandas as pd
import os
from datetime import datetime, timedelta
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Egypt Electronics API - Multi-Store")

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
    description: Optional[str] = ""
    link: Optional[str] = ""
    timestamp: str

class StoreStats(BaseModel):
    store: str
    total_products: int
    avg_price: float
    price_range: Dict[str, float]
    last_updated: str
    new_products_count: int
    price_changes_count: int

class ScrapeStatus(BaseModel):
    status: str
    message: str
    products_count: int = 0
    store_stats: List[StoreStats] = []

# Store configuration
STORES = {
    "microohm": {
        "name": "Microohm",
        "url": "https://microohm-eg.com",
        "csv_file": "microohm_products.csv"
    },
    "electrohub": {
        "name": "ElectroHub", 
        "url": "https://electrohub.com.eg",
        "csv_file": "electrohub_products.csv"
    },
    "ekostra": {
        "name": "Ekostra",
        "url": "https://ekostra.com",
        "csv_file": "ekostra_products.csv"
    },
    "ram": {
        "name": "RAM Electronics",
        "url": "https://ram-e-shop.com",
        "csv_file": "ram_products.csv"
    }
}

# Data directory
DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')
os.makedirs(DATA_DIR, exist_ok=True)

def get_store_csv_path(store_key: str) -> str:
    """Get CSV file path for a store"""
    return os.path.join(DATA_DIR, STORES[store_key]["csv_file"])

def load_store_products(store_key: str) -> List[Product]:
    """Load products from a store's CSV file"""
    csv_path = get_store_csv_path(store_key)
    
    if not os.path.exists(csv_path):
        logger.info(f"Creating new CSV for {STORES[store_key]['name']}")
        return []
    
    try:
        df = pd.read_csv(csv_path)
        products = []
        
        for idx, row in df.iterrows():
            product = Product(
                id=int(row['id']),
                name=str(row['name']),
                price=float(row['price']),
                image=str(row['image']),
                brand=str(row['brand']),
                category=str(row['category']),
                store=str(row['store']),
                availability=str(row['availability']),
                rating=float(row['rating']),
                description=str(row.get('description', '')),
                link=str(row.get('link', '')),
                timestamp=str(row['timestamp'])
            )
            products.append(product)
        
        logger.info(f"Loaded {len(products)} products from {STORES[store_key]['name']}")
        return products
        
    except Exception as e:
        logger.error(f"Error loading {store_key} CSV: {e}")
        return []

def save_store_products(store_key: str, products: List[Product]):
    """Save products to a store's CSV file"""
    csv_path = get_store_csv_path(store_key)
    
    try:
        data = []
        for product in products:
            data.append({
                'id': product.id,
                'name': product.name,
                'price': product.price,
                'image': product.image,
                'brand': product.brand,
                'category': product.category,
                'store': product.store,
                'availability': product.availability,
                'rating': product.rating,
                'description': product.description,
                'link': product.link,
                'timestamp': product.timestamp
            })
        
        df = pd.DataFrame(data)
        df.to_csv(csv_path, index=False)
        logger.info(f"Saved {len(products)} products to {STORES[store_key]['name']}")
        return True
        
    except Exception as e:
        logger.error(f"Error saving {store_key} CSV: {e}")
        return False

def track_price_changes(store_key: str, old_products: List[Product], new_products: List[Product]) -> Dict:
    """Track price changes and new products"""
    old_dict = {p.name: p for p in old_products}
    new_dict = {p.name: p for p in new_products}
    
    price_changes = []
    new_products_found = []
    
    # Check for price changes
    for name, new_product in new_dict.items():
        if name in old_dict:
            old_product = old_dict[name]
            if old_product.price != new_product.price:
                price_changes.append({
                    'name': name,
                    'old_price': old_product.price,
                    'new_price': new_product.price,
                    'change_percent': ((new_product.price - old_product.price) / old_product.price) * 100,
                    'timestamp': datetime.now().isoformat()
                })
        else:
            new_products_found.append(new_product)
    
    # Log changes
    if price_changes:
        log_file = os.path.join(DATA_DIR, f"{store_key}_price_changes.log")
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(f"\n=== Price Changes - {datetime.now().isoformat()} ===\n")
            for change in price_changes:
                f.write(f"{change['name']}: {change['old_price']} -> {change['new_price']} ({change['change_percent']:.1f}%)\n")
    
    if new_products_found:
        log_file = os.path.join(DATA_DIR, f"{store_key}_new_products.log")
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(f"\n=== New Products - {datetime.now().isoformat()} ===\n")
            for product in new_products_found:
                f.write(f"{product.name}: {product.price} EGP\n")
    
    return {
        'price_changes': price_changes,
        'new_products': new_products_found
    }

def generate_sample_data(store_key: str) -> List[Product]:
    """Generate sample data for a store"""
    store_name = STORES[store_key]["name"]
    timestamp = datetime.now().isoformat()
    
    sample_data = {
        "microohm": [
            ("Arduino Uno R3 Development Board", 450.0, "Arduino", "Development Boards"),
            ("ESP32-CAM + ESP32-CAM-MB – 2MP OV2640", 165.0, "Espressif", "Wireless Modules"),
            ("Raspberry Pi 4 Model B 4GB RAM", 1250.0, "Raspberry Pi", "Single Board Computers"),
            ("Arduino Mega 2560", 650.0, "Arduino", "Development Boards"),
            ("ESP8266 NodeMCU Lua", 75.0, "Espressif", "Wireless Modules"),
            ("Breadboard 830 Points", 45.0, "Generic", "Components"),
            ("Jumper Wires 120pcs", 35.0, "Generic", "Components"),
            ("DC Motor 12V 100RPM", 125.0, "Generic", "Motors"),
            ("LED Assortment 100pcs", 55.0, "Generic", "Components"),
            ("Soldering Iron Station", 280.0, "Generic", "Tools"),
            ("Arduino Nano 33 IoT", 220.0, "Arduino", "Development Boards"),
            ("ESP32-S3 DevKit", 185.0, "Espressif", "Wireless Modules"),
            ("Raspberry Pi Zero 2 W", 95.0, "Raspberry Pi", "Single Board Computers"),
            ("Arduino Due", 850.0, "Arduino", "Development Boards"),
            ("ESP32 LoRa", 195.0, "Espressif", "Wireless Modules"),
            ("Breadboard 400 Points", 25.0, "Generic", "Components"),
            ("Jumper Wires Male-Female 40pcs", 28.0, "Generic", "Components"),
            ("DC Motor 6V 200RPM", 85.0, "Generic", "Motors"),
            ("RGB LED Strip 5m", 125.0, "Generic", "Components"),
            ("Digital Soldering Station", 350.0, "Generic", "Tools"),
            ("Arduino Pro Mini", 95.0, "Arduino", "Development Boards"),
            ("ESP32-C3 DevKit", 125.0, "Espressif", "Wireless Modules"),
            ("Raspberry Pi CM4", 450.0, "Raspberry Pi", "Single Board Computers"),
            ("Arduino Leonardo", 380.0, "Arduino", "Development Boards"),
            ("ESP8266 ESP-01", 15.0, "Espressif", "Wireless Modules"),
            ("Prototype PCB Board 5x10cm", 18.0, "Generic", "Components"),
            ("Dupont Wires 200pcs", 42.0, "Generic", "Components"),
            ("Stepper Motor 28BYJ-48", 55.0, "Generic", "Motors"),
            ("LED 5mm Blue 100pcs", 35.0, "Generic", "Components"),
            ("Hot Air Gun Station", 450.0, "Generic", "Tools"),
            ("Arduino MKR WiFi 1010", 550.0, "Arduino", "Development Boards"),
            ("ESP32-WROOM-32 Module", 85.0, "Espressif", "Wireless Modules"),
            ("Raspberry Pi Compute Module 3+", 320.0, "Raspberry Pi", "Single Board Computers"),
            ("Arduino Portenta H7", 950.0, "Arduino", "Development Boards"),
            ("ESP32-PoE", 145.0, "Espressif", "Wireless Modules"),
            ("Perfboard 10x15cm", 22.0, "Generic", "Components"),
            ("Hook-up Wire 22AWG 100m", 38.0, "Generic", "Components"),
            ("Servo Motor MG996R", 95.0, "Generic", "Motors"),
            ("LED 5mm Red 100pcs", 32.0, "Generic", "Components"),
            ("Multimeter Digital", 180.0, "Generic", "Tools"),
            ("Arduino Nano 33 BLE", 420.0, "Arduino", "Development Boards"),
            ("ESP32-S2 DevKit", 155.0, "Espressif", "Wireless Modules"),
            ("Raspberry Pi Pico", 65.0, "Raspberry Pi", "Microcontrollers"),
            ("Arduino Starter Kit Advanced", 1850.0, "Arduino", "Kits"),
            ("ESP32 Camera Module", 115.0, "Espressif", "Wireless Modules"),
            ("Raspberry Pi 400", 1450.0, "Raspberry Pi", "Single Board Computers"),
            ("Arduino Ethernet Shield 2", 280.0, "Arduino", "Development Boards"),
            ("ESP32 Voice Recognition", 175.0, "Espressif", "Wireless Modules"),
            ("Raspberry Pi High Quality Camera", 550.0, "Raspberry Pi", "Cameras"),
            ("Arduino Motor Shield Rev3", 145.0, "Arduino", "Motor Control"),
            ("ESP32 OLED Module", 95.0, "Espressif", "Wireless Modules")
        ],
        "electrohub": [
            ("Raspberry Pi Pico W", 95.0, "Raspberry Pi", "Microcontrollers"),
            ("ESP32 DevKit V1 WiFi Bluetooth", 85.0, "Espressif", "Wireless Modules"),
            ("Arduino Nano Every", 220.0, "Arduino", "Development Boards"),
            ("Raspberry Pi 3 Model B+", 750.0, "Raspberry Pi", "Single Board Computers"),
            ("OLED Display 128x64 I2C", 65.0, "Generic", "Displays"),
            ("Ultrasonic Sensor HC-SR04", 25.0, "Generic", "Sensors"),
            ("PIR Motion Sensor", 30.0, "Generic", "Sensors"),
            ("Relay 5V 1 Channel", 25.0, "Generic", "Components"),
            ("Servo Motor SG90", 85.0, "Generic", "Motors"),
            ("LCD Display 16x2 Blue", 45.0, "Generic", "Displays"),
            ("Raspberry Pi 4 Case", 35.0, "Generic", "Accessories"),
            ("ESP32-S2 Mini", 45.0, "Espressif", "Wireless Modules"),
            ("Arduino Uno WiFi Rev2", 650.0, "Arduino", "Development Boards"),
            ("Raspberry Pi 7" Touchscreen", 285.0, "Raspberry Pi", "Displays"),
            ("TFT Display 2.8" SPI", 125.0, "Generic", "Displays"),
            ("Infrared Sensor Module", 18.0, "Generic", "Sensors"),
            ("Sound Sensor Module", 22.0, "Generic", "Sensors"),
            ("Relay 8 Channel 5V", 85.0, "Generic", "Components"),
            ("Stepper Motor Driver ULN2003", 28.0, "Generic", "Motor Control"),
            ("LED Matrix 8x8", 55.0, "Generic", "Displays"),
            ("Raspberry Pi Camera Module v2", 185.0, "Raspberry Pi", "Cameras"),
            ("ESP32-CAM AI Thinker", 125.0, "Espressif", "Wireless Modules"),
            ("Arduino MKR Family", 750.0, "Arduino", "Development Boards"),
            ("Raspberry Pi Sense HAT", 145.0, "Raspberry Pi", "Sensors"),
            ("E-Paper Display 2.9", 95.0, "Generic", "Displays"),
            ("Gyroscope MPU6050", 35.0, "Generic", "Sensors"),
            ("Magnetic Sensor Hall Effect", 15.0, "Generic", "Sensors"),
            ("Relay 4 Channel 12V", 65.0, "Generic", "Components"),
            ("Motor Driver L298N", 45.0, "Generic", "Motor Control"),
            ("7-Segment Display 4 Digit", 28.0, "Generic", "Displays"),
            ("Raspberry Pi Power Supply", 55.0, "Generic", "Accessories"),
            ("ESP32 LoRa SX1278", 185.0, "Espressif", "Wireless Modules"),
            ("Arduino Robot Kit", 1250.0, "Arduino", "Robotics"),
            ("Raspberry Pi Heatsink", 12.0, "Generic", "Accessories"),
            ("TFT LCD 3.5" Touch", 165.0, "Generic", "Displays"),
            ("Accelerometer ADXL345", 25.0, "Generic", "Sensors"),
            ("Light Sensor LDR", 8.0, "Generic", "Sensors"),
            ("Relay 2 Channel 5V", 35.0, "Generic", "Components"),
            ("Servo Motor MG996R", 95.0, "Generic", "Motors"),
            ("OLED Display 0.96" I2C", 45.0, "Generic", "Displays"),
            ("Raspberry Pi GPIO Breakout", 18.0, "Generic", "Accessories"),
            ("ESP32 Bluetooth Audio", 155.0, "Espressif", "Wireless Modules"),
            ("Arduino Education Kit", 850.0, "Arduino", "Education"),
            ("Raspberry Pi PoE HAT", 125.0, "Raspberry Pi", "Accessories"),
            ("LED Strip WS2812B 1m", 75.0, "Generic", "Components"),
            ("Temperature Sensor DS18B20", 12.0, "Generic", "Sensors"),
            ("Relay 16 Channel 5V", 185.0, "Generic", "Components"),
            ("DC Motor 12V 3000RPM", 145.0, "Generic", "Motors"),
            ("LCD Display 20x4 Blue", 85.0, "Generic", "Displays"),
            ("Raspberry Pi Fan", 25.0, "Generic", "Accessories"),
            ("ESP32 GPS Module", 95.0, "Espressif", "Wireless Modules"),
            ("Arduino Industrial Shield", 450.0, "Arduino", "Industrial"),
            ("Raspberry Pi NVMe SSD", 285.0, "Raspberry Pi", "Storage")
        ],
        "ekostra": [
            ("RFID Module RC522", 55.0, "Generic", "RFID"),
            ("Fingerprint Sensor", 120.0, "Generic", "Sensors"),
            ("GPS Module NEO-6M", 185.0, "Generic", "GPS"),
            ("Bluetooth Module HC-05", 75.0, "Generic", "Wireless"),
            ("WiFi Module ESP8266", 95.0, "Espressif", "Wireless Modules"),
            ("Temperature Sensor DHT22", 35.0, "Generic", "Sensors"),
            ("Pressure Sensor BMP280", 45.0, "Generic", "Sensors"),
            ("Stepper Motor NEMA 17", 180.0, "Generic", "Motors"),
            ("Logic Analyzer 8 Channel", 450.0, "Generic", "Test Equipment"),
            ("Function Generator", 650.0, "Generic", "Test Equipment"),
            ("RFID Reader 125kHz", 85.0, "Generic", "RFID"),
            ("Face Recognition Camera", 285.0, "Generic", "Sensors"),
            ("GPS Module NEO-7M", 225.0, "Generic", "GPS"),
            ("Bluetooth Module HC-06", 65.0, "Generic", "Wireless"),
            ("WiFi Module ESP32-CAM", 125.0, "Espressif", "Wireless Modules"),
            ("Humidity Sensor AM2320", 42.0, "Generic", "Sensors"),
            ("Altitude Sensor BMP388", 55.0, "Generic", "Sensors"),
            ("Stepper Motor NEMA 23", 285.0, "Generic", "Motors"),
            ("Logic Analyzer 16 Channel", 650.0, "Generic", "Test Equipment"),
            ("Oscilloscope Handheld", 1250.0, "Generic", "Test Equipment"),
            ("NFC Module PN532", 95.0, "Generic", "RFID"),
            ("Iris Scanner Module", 450.0, "Generic", "Sensors"),
            ("GPS Module with Antenna", 285.0, "Generic", "GPS"),
            ("Bluetooth Audio Module", 185.0, "Generic", "Wireless"),
            ("WiFi Mesh Module ESP32", 165.0, "Espressif", "Wireless Modules"),
            ("Gas Sensor MQ-2", 28.0, "Generic", "Sensors"),
            ("Flow Sensor YF-S201", 65.0, "Generic", "Sensors"),
            ("Servo Motor Digital", 125.0, "Generic", "Motors"),
            ("Signal Generator 2 Channel", 850.0, "Generic", "Test Equipment"),
            ("Spectrum Analyzer", 2850.0, "Generic", "Test Equipment"),
            ("RFID Tag 100pcs", 45.0, "Generic", "RFID"),
            ("Voice Recognition Module", 185.0, "Generic", "Sensors"),
            ("GPS Tracker Module", 385.0, "Generic", "GPS"),
            ("Bluetooth BLE Module", 95.0, "Generic", "Wireless"),
            ("WiFi Router Module ESP32", 195.0, "Espressif", "Wireless Modules"),
            ("Current Sensor ACS712", 22.0, "Generic", "Sensors"),
            ("Vibration Sensor SW-420", 18.0, "Generic", "Sensors"),
            ("Brushless Motor ESC", 285.0, "Generic", "Motors"),
            ("Power Supply Variable", 1250.0, "Generic", "Test Equipment"),
            ("Network Analyzer", 4500.0, "Generic", "Test Equipment"),
            ("RFID Reader UHF", 285.0, "Generic", "RFID"),
            ("Gesture Sensor APDS9960", 65.0, "Generic", "Sensors"),
            ("GPS Module USB", 165.0, "Generic", "GPS"),
            ("Bluetooth Mesh Module", 145.0, "Generic", "Wireless"),
            ("WiFi Gateway ESP32", 285.0, "Espressif", "Wireless Modules"),
            ("Voltage Sensor ZMPT101B", 35.0, "Generic", "Sensors"),
            ("Tilt Sensor SW-520D", 12.0, "Generic", "Sensors"),
            ("Linear Actuator 12V", 385.0, "Generic", "Motors"),
            ("Battery Tester", 185.0, "Generic", "Test Equipment"),
            ("EMI Tester", 650.0, "Generic", "Test Equipment")
        ],
        "ram": [
            ("Digital Multimeter", 220.0, "Generic", "Test Equipment"),
            ("Oscilloscope Digital", 1250.0, "Generic", "Test Equipment"),
            ("Power Supply 30V 5A", 850.0, "Generic", "Power Supplies"),
            ("Resistor Kit 1/4W 1000pcs", 85.0, "Generic", "Components"),
            ("Capacitor Kit 100pcs", 95.0, "Generic", "Components"),
            ("Transistor Kit 200pcs", 120.0, "Generic", "Components"),
            ("Diode Kit 100pcs", 65.0, "Generic", "Components"),
            ("IC Kit 50 Types", 185.0, "Generic", "Components"),
            ("Arduino Starter Kit", 1250.0, "Arduino", "Kits"),
            ("3D Printer Kit", 2850.0, "Generic", "3D Printing"),
            ("Bench Power Supply 60V 5A", 1450.0, "Generic", "Power Supplies"),
            ("Handheld Oscilloscope", 1850.0, "Generic", "Test Equipment"),
            ("Lab Power Supply 30V 10A", 2250.0, "Generic", "Power Supplies"),
            ("Resistor Kit 1/2W 500pcs", 125.0, "Generic", "Components"),
            ("Capacitor Kit Electrolytic 200pcs", 165.0, "Generic", "Components"),
            ("Transistor Kit Power 100pcs", 285.0, "Generic", "Components"),
            ("LED Kit Assorted 500pcs", 185.0, "Generic", "Components"),
            ("IC Kit Logic 100pcs", 350.0, "Generic", "Components"),
            ("Raspberry Pi Kit Advanced", 1850.0, "Raspberry Pi", "Kits"),
            ("CNC Router Kit 3010", 4500.0, "Generic", "CNC"),
            ("Programmable Power Supply", 2850.0, "Generic", "Power Supplies"),
            ("Mixed Signal Oscilloscope", 3250.0, "Generic", "Test Equipment"),
            ("Triple Power Supply", 3850.0, "Generic", "Power Supplies"),
            ("SMD Resistor Kit 0805 200pcs", 185.0, "Generic", "Components"),
            ("SMD Capacitor Kit 0805 150pcs", 225.0, "Generic", "Components"),
            ("SMD Transistor Kit 100pcs", 285.0, "Generic", "Components"),
            ("SMD LED Kit 0805 300pcs", 325.0, "Generic", "Components"),
            ("IC Kit Microcontroller 50pcs", 450.0, "Generic", "Components"),
            ("Arduino Industrial Kit", 2250.0, "Arduino", "Kits"),
            ("Laser Cutter 40W", 6500.0, "Generic", "Laser"),
            ("DC Load Tester 60V 30A", 1850.0, "Generic", "Test Equipment"),
            ("Function Generator 20MHz", 1450.0, "Generic", "Test Equipment"),
            ("Linear Power Supply 60V 3A", 1850.0, "Generic", "Power Supplies"),
            ("Precision Resistor Kit 100pcs", 285.0, "Generic", "Components"),
            ("Tantalum Capacitor Kit 100pcs", 385.0, "Generic", "Components"),
            ("Power Transistor Kit 50pcs", 450.0, "Generic", "Components"),
            ("RGB LED Kit SMD 200pcs", 285.0, "Generic", "Components"),
            ("IC Kit Op-Amp 100pcs", 550.0, "Generic", "Components"),
            ("ESP32 Development Kit", 650.0, "Espressif", "Kits"),
            ("3D Printer Prusa i3 Kit", 8500.0, "Generic", "3D Printing"),
            ("Component Tester", 450.0, "Generic", "Test Equipment"),
            ("LCR Meter", 850.0, "Generic", "Test Equipment"),
            ("Adjustable Power Supply 12V 30A", 2850.0, "Generic", "Power Supplies"),
            ("Metal Film Resistor Kit 200pcs", 385.0, "Generic", "Components"),
            ("Film Capacitor Kit 100pcs", 485.0, "Generic", "Components"),
            ("Darlington Transistor Kit 50pcs", 285.0, "Generic", "Components"),
            ("COB LED Kit 50pcs", 385.0, "Generic", "Components"),
            ("IC Kit Timer 100pcs", 350.0, "Generic", "Components"),
            ("IoT Development Kit", 1250.0, "Generic", "Kits"),
            ("3D Printer Ender 3 Kit", 5500.0, "Generic", "3D Printing"),
            ("Waveform Generator", 2250.0, "Generic", "Test Equipment")
        ]
    }
    
    products = []
    for i, (name, price, brand, category) in enumerate(sample_data.get(store_key, [])):
        product = Product(
            id=i + 1,
            name=name,
            price=price,
            image=f"https://images.unsplash.com/photo-1553406830-ef2513450d76?w=300&h=300&fit=crop&sig={i}",
            brand=brand,
            category=category,
            store=store_name,
            availability="In Stock",
            rating=4.0 + (i % 10) * 0.1,
            description=f"High quality {category.lower()} from {brand}",
            link=f"https://{STORES[store_key]['url']}/product/{i+1}",
            timestamp=timestamp
        )
        products.append(product)
    
    return products

@app.get("/")
async def root():
    return {
        "message": "Egypt Electronics Multi-Store API",
        "stores": list(STORES.keys()),
        "data_directory": DATA_DIR
    }

@app.get("/api/products", response_model=List[Product])
async def get_all_products():
    """Get all products from all stores"""
    all_products = []
    
    for store_key in STORES.keys():
        products = load_store_products(store_key)
        all_products.extend(products)
    
    logger.info(f"Returning {len(all_products)} total products from all stores")
    return all_products

@app.get("/api/products/{store_key}", response_model=List[Product])
async def get_store_products(store_key: str):
    """Get products from a specific store"""
    if store_key not in STORES:
        return []
    
    return load_store_products(store_key)

@app.get("/api/stats")
async def get_stats():
    """Get statistics for all stores"""
    stats = []
    
    for store_key in STORES.keys():
        products = load_store_products(store_key)
        
        if not products:
            stats.append(StoreStats(
                store=STORES[store_key]["name"],
                total_products=0,
                avg_price=0,
                price_range={"min": 0, "max": 0},
                last_updated="Never",
                new_products_count=0,
                price_changes_count=0
            ))
            continue
        
        prices = [p.price for p in products if p.price > 0]
        avg_price = sum(prices) / len(prices) if prices else 0
        
        stats.append(StoreStats(
            store=STORES[store_key]["name"],
            total_products=len(products),
            avg_price=round(avg_price, 2),
            price_range={"min": min(prices) if prices else 0, "max": max(prices) if prices else 0},
            last_updated=max(p.timestamp for p in products) if products else "Never",
            new_products_count=0,
            price_changes_count=0
        ))
    
    return stats

@app.post("/api/scrape/{store_key}")
async def scrape_store(store_key: str):
    """Scrape a specific store and track changes"""
    if store_key not in STORES:
        return ScrapeStatus(
            status="error",
            message=f"Unknown store: {store_key}",
            products_count=0
        )
    
    try:
        # Import and use real scraper
        from real_scraper import MultiStoreScraper
        scraper = MultiStoreScraper()
        result = scraper.scrape_store(store_key)
        
        if 'error' in result:
            return ScrapeStatus(
                status="error",
                message=result['error'],
                products_count=0
            )
        
        return ScrapeStatus(
            status="completed",
            message=f"Scraped {result['products_count']} products from {STORES[store_key]['name']}. "
                   f"Found {result['new_products']} new products, {result['price_changes']} price changes.",
            products_count=result['products_count']
        )
        
    except Exception as e:
        logger.error(f"Error scraping {store_key}: {e}")
        # Fallback to sample data
        old_products = load_store_products(store_key)
        new_products = generate_sample_data(store_key)
        changes = track_price_changes(store_key, old_products, new_products)
        
        if save_store_products(store_key, new_products):
            return ScrapeStatus(
                status="completed",
                message=f"Used sample data for {STORES[store_key]['name']}. "
                       f"Found {len(changes['new_products'])} new products, {len(changes['price_changes'])} price changes.",
                products_count=len(new_products)
            )
        else:
            return ScrapeStatus(
                status="error",
                message=f"Failed to save {STORES[store_key]['name']} products",
                products_count=0
            )

@app.post("/api/scrape/all")
async def scrape_all_stores():
    """Scrape all stores"""
    results = []
    total_products = 0
    
    for store_key in STORES.keys():
        result = await scrape_store(store_key)
        results.append(result)
        total_products += result.products_count
    
    return ScrapeStatus(
        status="completed",
        message=f"Scraped all {len(STORES)} stores",
        products_count=total_products
    )

@app.post("/api/init-sample-data")
async def init_sample_data():
    """Initialize sample data for all stores"""
    total_products = 0
    
    for store_key in STORES.keys():
        products = generate_sample_data(store_key)
        if save_store_products(store_key, products):
            total_products += len(products)
            logger.info(f"Initialized {len(products)} products for {STORES[store_key]['name']}")
    
    return {
        "message": f"Initialized {total_products} sample products across {len(STORES)} stores",
        "stores": list(STORES.keys())
    }

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Egypt Electronics Multi-Store API...")
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
