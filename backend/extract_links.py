import pandas as pd
import os

def extract_all_links():
    """Extract all product links from the 4000 products"""
    data_dir = os.path.join(os.path.dirname(__file__), 'data')
    
    all_links = []
    stores = ['microohm', 'electrohub', 'ekostra', 'ram']
    
    print("EXTRACTING ALL 4000 PRODUCT LINKS")
    print("=" * 60)
    
    for store in stores:
        csv_path = os.path.join(data_dir, f'{store}_products.csv')
        if os.path.exists(csv_path):
            df = pd.read_csv(csv_path)
            
            print(f"\n{store.upper()} STORE ({len(df)} products):")
            print("-" * 40)
            
            for i, row in df.iterrows():
                product_info = {
                    'id': row['id'],
                    'name': row['name'],
                    'price': row['price'],
                    'store': row['store'],
                    'category': row['category'],
                    'link': row['link']
                }
                all_links.append(product_info)
                
                # Display first 10 products per store
                if i < 10:
                    print(f"{i+1:3d}. {row['name'][:50]:50s} | {row['price']:8.2f} EGP | {row['link']}")
                elif i == 10:
                    print(f"... and {len(df) - 10} more products")
                    break
    
    print(f"\nTOTAL PRODUCTS WITH LINKS: {len(all_links)}")
    print("=" * 60)
    
    # Save all links to a file
    links_file = os.path.join(data_dir, 'all_4000_links.txt')
    with open(links_file, 'w', encoding='utf-8') as f:
        f.write("ALL 4000 PRODUCT LINKS\n")
        f.write("=" * 60 + "\n\n")
        
        for store in stores:
            csv_path = os.path.join(data_dir, f'{store}_products.csv')
            if os.path.exists(csv_path):
                df = pd.read_csv(csv_path)
                f.write(f"\n{store.upper()} STORE ({len(df)} products):\n")
                f.write("-" * 40 + "\n")
                
                for i, row in df.iterrows():
                    f.write(f"{i+1:4d}. {row['name'][:60]:60s} | {row['price']:8.2f} EGP | {row['link']}\n")
    
    print(f"All links saved to: {links_file}")
    
    # Show link statistics
    print(f"\nLINK STATISTICS:")
    print(f"Total unique links: {len(set([p['link'] for p in all_links]))}")
    
    # Show links by store
    store_links = {}
    for product in all_links:
        store = product['store']
        if store not in store_links:
            store_links[store] = []
        store_links[store].append(product['link'])
    
    for store, links in store_links.items():
        print(f"{store}: {len(links)} links")
    
    return all_links

if __name__ == "__main__":
    links = extract_all_links()
