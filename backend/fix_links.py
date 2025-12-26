import csv
import os

def fix_microohm_links():
    """Fix Microohm product links to point to correct URLs"""
    csv_file = 'data/microohm_products.csv'
    
    if not os.path.exists(csv_file):
        print(f"File {csv_file} not found")
        return
    
    updated_products = []
    
    with open(csv_file, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            # Fix the link to point to the actual store
            product_id = row['id']
            row['link'] = f'https://microohm-eg.com/product/{product_id}'
            updated_products.append(row)
    
    # Write back to CSV
    with open(csv_file, 'w', newline='', encoding='utf-8') as file:
        fieldnames = updated_products[0].keys()
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(updated_products)
    
    print(f"Fixed {len(updated_products)} Microohm product links")

def fix_all_store_links():
    """Fix links for all store CSV files"""
    stores = ['microohm', 'electrohub', 'ekostra', 'ram']
    
    for store in stores:
        csv_file = f'data/{store}_products.csv'
        
        if not os.path.exists(csv_file):
            print(f"File {csv_file} not found")
            continue
        
        updated_products = []
        
        with open(csv_file, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                # Fix the link to point to the actual store
                product_id = row['id']
                
                if store == 'microohm':
                    row['link'] = f'https://microohm-eg.com/product/{product_id}'
                elif store == 'electrohub':
                    row['link'] = f'https://electrohub-eg.com/product/{product_id}'
                elif store == 'ekostra':
                    row['link'] = f'https://ekostra-eg.com/product/{product_id}'
                elif store == 'ram':
                    row['link'] = f'https://ram-egypt.com/product/{product_id}'
                
                updated_products.append(row)
        
        # Write back to CSV
        with open(csv_file, 'w', newline='', encoding='utf-8') as file:
            fieldnames = updated_products[0].keys()
            writer = csv.DictWriter(file, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(updated_products)
        
        print(f"Fixed {len(updated_products)} {store} product links")

if __name__ == "__main__":
    print("Fixing product links...")
    fix_all_store_links()
    print("All product links have been fixed!")
