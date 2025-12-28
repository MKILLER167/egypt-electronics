import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final List<Product> allProducts;
  final List<String> favorites;
  final List<String> compareList;
  final Function(String) onToggleFavorite;
  final Function(String) onToggleCompare;

  const ProductDetailScreen({
    Key? key,
    required this.product,
    required this.allProducts,
    required this.favorites,
    required this.compareList,
    required this.onToggleFavorite,
    required this.onToggleCompare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFavorite = favorites.contains(product.id);
    final isCompare = compareList.contains(product.id);
    final similarProducts = allProducts
        .where((p) => p.id != product.id && (p.category == product.category || p.brand == product.brand))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Product Details'),
        actions: [
          IconButton(
            onPressed: () => onToggleFavorite(product.id),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          IconButton(
            onPressed: () => onToggleCompare(product.id),
            icon: Icon(
              Icons.compare_arrows,
              color: isCompare ? Colors.blue : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
              ),
              child: product.image != null
                  ? Image.network(
                      product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported, color: AppColors.textMuted, size: 80),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.inventory_2, color: AppColors.textMuted, size: 80),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Rating and Availability
                  Row(
                    children: [
                      // Rating
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < product.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 20,
                              color: index < product.rating.floor()
                                  ? Colors.amber
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product.rating}/5.0',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 24),
                      
                      // Availability
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.availability == 'In Stock'
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.availability,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      InfoCard(
                        label: 'Brand',
                        value: product.brand,
                        icon: Icons.branding_watermark,
                      ),
                      InfoCard(
                        label: 'Category',
                        value: product.category,
                        icon: Icons.category,
                      ),
                      InfoCard(
                        label: 'Store',
                        value: product.store,
                        icon: Icons.store,
                      ),
                      InfoCard(
                        label: 'Status',
                        value: product.availability,
                        icon: Icons.info,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Price and CTA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surface,
                          AppColors.surfaceLight,
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.border,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Best Price',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Save 20%',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${product.price.toInt()} EGP',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Redirecting to store...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart),
                                SizedBox(width: 8),
                                Text(
                                  'View at Store',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Product Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'High-quality ${product.name.toLowerCase()} available at ${product.store}. Perfect for your electronics projects and prototyping needs. This product comes with manufacturer warranty and is guaranteed authentic.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Similar Products
                  if (similarProducts.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Similar Products You May Like',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: similarProducts.length,
                      itemBuilder: (context, index) {
                        final similarProduct = similarProducts[index];
                        return SimilarProductCard(
                          product: similarProduct,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: similarProduct,
                                  allProducts: allProducts,
                                  favorites: favorites,
                                  compareList: compareList,
                                  onToggleFavorite: onToggleFavorite,
                                  onToggleCompare: onToggleCompare,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const InfoCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class SimilarProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const SimilarProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: product.image != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported, color: AppColors.textMuted, size: 30),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.inventory_2, color: AppColors.textMuted, size: 30),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${product.price.toInt()} EGP',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.store,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
