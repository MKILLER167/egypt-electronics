import pandas as pd
import os
from datetime import datetime
import random

def generate_1000_products_per_store():
    """Generate 1000 diverse products for each store"""
    
    # Product templates and variations
    base_products = {
        'microohm': {
            'categories': ['Development Boards', 'Wireless Modules', 'Components', 'Motors', 'Tools', 'Sensors', 'Displays', 'Power Supplies', 'Kits', 'Robotics'],
            'brands': ['Arduino', 'Espressif', 'Raspberry Pi', 'Microchip', 'STMicroelectronics', 'Texas Instruments', 'Analog Devices', 'NXP', 'Generic'],
            'base_names': [
                'Arduino {} Development Board', 'ESP32 {} Module', 'Raspberry Pi {}', 'STM32 {}', 'PIC {}', 'AVR {}', 'ARM {}', 'FPGA {}', 'Sensor {}', 'Motor {}',
                'Display {}', 'Power Supply {}', 'Kit {}', 'Robot {}', 'Drone {}', 'Camera {}', 'GPS {}', 'Bluetooth {}', 'WiFi {}', 'LoRa {}'
            ],
            'price_ranges': {
                'Development Boards': (50, 2000),
                'Wireless Modules': (20, 500),
                'Components': (5, 200),
                'Motors': (25, 800),
                'Tools': (30, 1500),
                'Sensors': (15, 300),
                'Displays': (40, 600),
                'Power Supplies': (100, 3000),
                'Kits': (200, 5000),
                'Robotics': (500, 10000)
            }
        },
        'electrohub': {
            'categories': ['Single Board Computers', 'Microcontrollers', 'Displays', 'Sensors', 'Wireless', 'Accessories', 'Kits', 'Industrial', 'IoT', 'Education'],
            'brands': ['Raspberry Pi', 'Arduino', 'ESP', 'Samsung', 'LG', 'Sony', 'Panasonic', 'Intel', 'AMD', 'Generic'],
            'base_names': [
                'Raspberry Pi {}', 'Arduino {}', 'ESP {}', 'Samsung {}', 'LG {}', 'Sony {}', 'Intel {}', 'AMD {}', 'Display {}', 'Sensor {}',
                'Module {}', 'Adapter {}', 'Cable {}', 'Case {}', 'Heatsink {}', 'Fan {}', 'Power {}', 'Storage {}', 'Network {}', 'Camera {}'
            ],
            'price_ranges': {
                'Single Board Computers': (100, 2500),
                'Microcontrollers': (30, 800),
                'Displays': (50, 1000),
                'Sensors': (20, 400),
                'Wireless': (25, 300),
                'Accessories': (10, 200),
                'Kits': (150, 3000),
                'Industrial': (200, 8000),
                'IoT': (50, 1500),
                'Education': (100, 4000)
            }
        },
        'ekostra': {
            'categories': ['RFID', 'Sensors', 'GPS', 'Wireless', 'Modules', 'Test Equipment', 'Security', 'Automation', 'Communication', 'Embedded'],
            'brands': ['Texas Instruments', 'Analog Devices', 'STMicroelectronics', 'NXP', 'Maxim Integrated', 'Silicon Labs', 'Espressif', 'Generic'],
            'base_names': [
                'RFID {}', 'Sensor {}', 'GPS {}', 'Bluetooth {}', 'WiFi {}', 'Module {}', 'Tester {}', 'Security {}', 'Automation {}', 'Communication {}',
                'Transceiver {}', 'Receiver {}', 'Transmitter {}', 'Controller {}', 'Processor {}', 'Memory {}', 'Interface {}', 'Converter {}', 'Amplifier {}', 'Filter {}'
            ],
            'price_ranges': {
                'RFID': (30, 500),
                'Sensors': (25, 800),
                'GPS': (50, 1000),
                'Wireless': (20, 600),
                'Modules': (40, 1200),
                'Test Equipment': (100, 5000),
                'Security': (80, 2000),
                'Automation': (150, 4000),
                'Communication': (60, 1500),
                'Embedded': (100, 3000)
            }
        },
        'ram': {
            'categories': ['Test Equipment', 'Power Supplies', 'Components', 'Tools', 'Measurement', 'Industrial', 'Laboratory', 'Calibration', 'Analysis', 'Professional'],
            'brands': ['Fluke', 'Keysight', 'Tektronix', 'Rigol', 'Siglent', 'BK Precision', 'HP', 'Agilent', 'Generic'],
            'base_names': [
                'Digital Multimeter {}', 'Oscilloscope {}', 'Power Supply {}', 'Function Generator {}', 'Spectrum Analyzer {}', 'Logic Analyzer {}', 'Component Tester {}',
                'LCR Meter {}', 'Frequency Counter {}', 'Arbitrary Waveform Generator {}', 'DC Load {}', 'Battery Tester {}', 'EMI Tester {}', 'Network Analyzer {}',
                'Signal Generator {}', 'Power Analyzer {}', 'Thermal Camera {}', 'Vibration Analyzer {}', 'Calibration {}', 'Professional {}'
            ],
            'price_ranges': {
                'Test Equipment': (100, 15000),
                'Power Supplies': (200, 8000),
                'Components': (50, 1000),
                'Tools': (80, 3000),
                'Measurement': (150, 12000),
                'Industrial': (300, 20000),
                'Laboratory': (500, 25000),
                'Calibration': (200, 10000),
                'Analysis': (400, 30000),
                'Professional': (1000, 50000)
            }
        }
    }
    
    # Suffixes for product variations
    suffixes = [
        'Pro', 'Plus', 'Max', 'Ultra', 'Elite', 'Premium', 'Advanced', 'Professional', 'Industrial', 'Commercial',
        'Mini', 'Micro', 'Nano', 'Compact', 'Portable', 'Handheld', 'Desktop', 'Rack Mount', 'Panel Mount', 'Board Level',
        'Kit', 'Set', 'Package', 'Bundle', 'Combo', 'Starter', 'Deluxe', 'Standard', 'Basic', 'Entry Level',
        'High Speed', 'High Precision', 'High Accuracy', 'High Resolution', 'High Power', 'Low Power', 'Ultra Low Power',
        'Wireless', 'Bluetooth', 'WiFi', 'Ethernet', 'USB', 'RS232', 'RS485', 'CAN', 'SPI', 'I2C',
        'Digital', 'Analog', 'Mixed Signal', 'Smart', 'Intelligent', 'Programmable', 'Configurable', 'Modular',
        'Version 2.0', 'Version 3.0', 'Version 4.0', 'Version 5.0', '2023 Model', '2024 Model', '2025 Model',
        'Type A', 'Type B', 'Type C', 'Series 1', 'Series 2', 'Series 3', 'Generation 1', 'Generation 2', 'Generation 3',
        'Model X', 'Model Y', 'Model Z', 'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta'
    ]
    
    data_dir = os.path.join(os.path.dirname(__file__), 'data')
    os.makedirs(data_dir, exist_ok=True)
    
    total_products = 0
    
    for store_key, store_config in base_products.items():
        products = []
        store_name = store_config['brands'][0] if 'microohm' in store_key else store_key.title()
        
        print(f"Generating 1000 products for {store_name}...")
        
        for i in range(1000):
            # Select category
            category = random.choice(store_config['categories'])
            price_range = store_config['price_ranges'][category]
            
            # Select brand
            brand = random.choice(store_config['brands'])
            
            # Generate product name
            base_name = random.choice(store_config['base_names'])
            suffix = random.choice(suffixes) if random.random() < 0.7 else ''
            
            # Format the name
            if '{}' in base_name:
                if suffix:
                    name = base_name.format(f"{suffix} {i+1}")
                else:
                    name = base_name.format(f"Model {i+1}")
            else:
                name = f"{base_name} {suffix} {i+1}" if suffix else f"{base_name} {i+1}"
            
            # Generate price within category range
            price = round(random.uniform(price_range[0], price_range[1]), 2)
            
            # Add some price variation for similar products
            if i % 10 < 8:  # 80% of products have small variations
                price += random.uniform(-price * 0.2, price * 0.2)
                price = max(price_range[0], min(price_range[1], price))
                price = round(price, 2)
            
            product = {
                'id': i + 1,
                'name': name,
                'price': price,
                'image': f"https://images.unsplash.com/photo-1553406830-ef2513450d76?w=300&h=300&fit=crop&sig={store_key}_{i}",
                'brand': brand,
                'category': category,
                'store': store_name,
                'availability': random.choice(['In Stock', 'In Stock', 'In Stock', 'Limited Stock', 'Out of Stock']),
                'rating': round(random.uniform(3.5, 5.0), 1),
                'description': f"Professional {category.lower()} from {brand}. High quality and reliable performance for all applications.",
                'link': f"https://{store_config['brands'][0].lower()}.com/product/{i+1}",
                'timestamp': datetime.now().isoformat()
            }
            
            products.append(product)
        
        # Save to CSV
        csv_path = os.path.join(data_dir, f'{store_key}_products.csv')
        df = pd.DataFrame(products)
        df.to_csv(csv_path, index=False)
        
        print(f"Saved {len(products)} products to {csv_path}")
        total_products += len(products)
    
    print(f"\nTOTAL PRODUCTS GENERATED: {total_products}")
    print("=" * 50)
    
    # Generate summary
    for store_key in base_products.keys():
        csv_path = os.path.join(data_dir, f'{store_key}_products.csv')
        if os.path.exists(csv_path):
            df = pd.read_csv(csv_path)
            print(f"{store_key.title()}: {len(df)} products")
            
            # Category breakdown
            categories = df['category'].value_counts()
            print(f"  Categories: {len(categories)}")
            for cat, count in categories.head(5).items():
                print(f"    {cat}: {count}")
            
            # Price range
            prices = df['price']
            print(f"  Price range: {prices.min():.2f} - {prices.max():.2f} EGP")
            print(f"  Average price: {prices.mean():.2f} EGP")
            print()
    
    return total_products

if __name__ == "__main__":
    generate_1000_products_per_store()
