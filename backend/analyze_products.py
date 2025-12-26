import pandas as pd
import os
from collections import Counter

def analyze_all_products():
    """Analyze and categorize all products from all stores"""
    data_dir = os.path.join(os.path.dirname(__file__), 'data')
    all_products = []
    
    # Load all CSV files
    stores = ['microohm', 'electrohub', 'ekostra', 'ram']
    
    for store in stores:
        csv_path = os.path.join(data_dir, f'{store}_products.csv')
        if os.path.exists(csv_path):
            df = pd.read_csv(csv_path)
            all_products.extend(df.to_dict('records'))
    
    print(f"TOTAL PRODUCTS: {len(all_products)}")
    print("=" * 60)
    
    # Categorize by store
    store_counts = Counter([p['store'] for p in all_products])
    print("\nPRODUCTS BY STORE:")
    for store, count in store_counts.most_common():
        print(f"  {store}: {count} products")
    
    # Categorize by category
    category_counts = Counter([p['category'] for p in all_products])
    print(f"\nPRODUCTS BY CATEGORY ({len(category_counts)} categories):")
    for category, count in category_counts.most_common():
        print(f"  {category}: {count} products")
    
    # Categorize by brand
    brand_counts = Counter([p['brand'] for p in all_products])
    print(f"\nPRODUCTS BY BRAND ({len(brand_counts)} brands):")
    for brand, count in brand_counts.most_common():
        print(f"  {brand}: {count} products")
    
    # Price ranges
    prices = [float(p['price']) for p in all_products if p['price'] > 0]
    if prices:
        print(f"\nPRICE ANALYSIS:")
        print(f"  Lowest price: {min(prices):.2f} EGP")
        print(f"  Highest price: {max(prices):.2f} EGP")
        print(f"  Average price: {sum(prices)/len(prices):.2f} EGP")
        
        # Price ranges
        price_ranges = {
            'Under 100 EGP': len([p for p in prices if p < 100]),
            '100-500 EGP': len([p for p in prices if 100 <= p < 500]),
            '500-1000 EGP': len([p for p in prices if 500 <= p < 1000]),
            '1000-5000 EGP': len([p for p in prices if 1000 <= p < 5000]),
            'Over 5000 EGP': len([p for p in prices if p >= 5000])
        }
        
        print(f"\nPRICE RANGES:")
        for range_name, count in price_ranges.items():
            print(f"  {range_name}: {count} products")
    
    # Availability
    availability_counts = Counter([p['availability'] for p in all_products])
    print(f"\nAVAILABILITY:")
    for status, count in availability_counts.items():
        print(f"  {status}: {count} products")
    
    # Rating distribution
    ratings = [float(p['rating']) for p in all_products if p['rating'] > 0]
    if ratings:
        print(f"\nRATING ANALYSIS:")
        print(f"  Average rating: {sum(ratings)/len(ratings):.2f} / 5")
        print(f"  Highest rating: {max(ratings):.2f} / 5")
        print(f"  Lowest rating: {min(ratings):.2f} / 5")
    
    # Detailed category breakdown
    print(f"\nDETAILED CATEGORY BREAKDOWN:")
    print("=" * 60)
    
    categories = {}
    for product in all_products:
        cat = product['category']
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(product)
    
    for category, products in sorted(categories.items(), key=lambda x: len(x[1]), reverse=True):
        print(f"\n{category.upper()} ({len(products)} products):")
        print("-" * 40)
        
        # Group by store in this category
        store_breakdown = Counter([p['store'] for p in products])
        for store, count in store_breakdown.most_common():
            print(f"  {store}: {count} products")
        
        # Show price range for this category
        cat_prices = [float(p['price']) for p in products if p['price'] > 0]
        if cat_prices:
            print(f"  Price range: {min(cat_prices):.2f} - {max(cat_prices):.2f} EGP")
        
        # Show top 3 most expensive products in this category
        sorted_products = sorted(products, key=lambda x: float(x['price']), reverse=True)[:3]
        print(f"  Top products:")
        for i, product in enumerate(sorted_products, 1):
            print(f"    {i}. {product['name']} - {product['price']} EGP")
    
    return all_products

if __name__ == "__main__":
    products = analyze_all_products()
