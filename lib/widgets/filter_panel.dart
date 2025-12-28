import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Brand Filter
              _buildDropdown(
                'Brand',
                provider.selectedBrand,
                provider.brands,
                (value) => provider.updateSelectedBrand(value),
              ),
              
              const SizedBox(height: 16),
              
              // Store Filter
              _buildDropdown(
                'Store',
                provider.selectedStore,
                provider.stores,
                (value) => provider.updateSelectedStore(value),
              ),
              
              const SizedBox(height: 16),
              
              // Category Filter
              _buildDropdown(
                'Category',
                provider.selectedCategory,
                provider.categories,
                (value) => provider.updateSelectedCategory(value),
              ),
              
              const SizedBox(height: 16),
              
              // Sort By Filter
              _buildDropdown(
                'Sort By',
                provider.sortBy,
                ['name', 'price-low', 'price-high', 'rating'],
                (value) => provider.updateSortBy(value),
                labels: const {
                  'name': 'Name (A-Z)',
                  'price-low': 'Price: Low to High',
                  'price-high': 'Price: High to Low',
                  'rating': 'Highest Rated',
                },
              ),
              
              const SizedBox(height: 16),
              
              // Price Range Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Max Price: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${provider.priceRange.end.toInt()} EGP',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: provider.priceRange,
                    min: 0,
                    max: 2000,
                    divisions: 20,
                    activeColor: Colors.red.shade600,
                    inactiveColor: Colors.grey[300],
                    onChanged: (values) {
                      provider.updatePriceRange(values);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Clear Filters Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.clearFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Clear All Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildDropdown(
  String label,
  String value,
  List<String> items,
  Function(String) onChanged, {
  Map<String, String>? labels,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  labels?[item] ?? item,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ),
    ],
  );
}
