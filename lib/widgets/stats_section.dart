import 'package:flutter/material.dart';
import '../providers/product_provider.dart';

class StatsSection extends StatelessWidget {
  final ProductProvider provider;

  const StatsSection({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final stats = {
      'totalProducts': provider.products.length,
      'totalStores': provider.stores.length - 1,
      'avgPrice': provider.products.isNotEmpty
          ? provider.products
                  .map((p) => p.price)
                  .reduce((a, b) => a + b) /
              provider.products.length
          : 0,
      'lowestPrice': provider.products.isNotEmpty
          ? provider.products.map((p) => p.price).reduce((a, b) => a < b ? a : b)
          : 0,
    };

    return Container(
      margin: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          StatCard(
            icon: Icons.inventory_2,
            value: '${stats['totalProducts']}',
            label: 'Products',
            color: Colors.blue,
          ),
          StatCard(
            icon: Icons.store,
            value: '${stats['totalStores']}',
            label: 'Stores',
            color: Colors.purple,
          ),
          StatCard(
            icon: Icons.trending_up,
            value: '${stats['avgPrice']?.round()} EGP',
            label: 'Avg Price',
            color: Colors.green,
          ),
          StatCard(
            icon: Icons.bolt,
            value: '${stats['lowestPrice']?.round()} EGP',
            label: 'Best Price',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
