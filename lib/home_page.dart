import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'models/product.dart';
import 'product_detail_screen.dart';
import 'compare_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiUrl = 'http://127.0.0.1:8000';
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<String> favorites = [];
  List<String> compareList = [];
  List<String> recentlyViewed = [];
  
  String searchQuery = '';
  String selectedBrand = 'All';
  String selectedStore = 'All';
  String selectedCategory = 'All';
  double maxPrice = 2000;
  String sortBy = 'name';
  bool showFilters = false;
  bool isLoading = true;
  String currentPage = 'home';
  bool viewGrid = true;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          filterProducts();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load products')),
      );
    }
  }

  Future<void> scrapeProducts() async {
    try {
      await http.post(Uri.parse('$apiUrl/api/scrape'));
      await Future.delayed(const Duration(seconds: 3));
      await loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${products.length} products!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update products')),
        );
      }
    }
  }

  void filterProducts() {
    setState(() {
      filteredProducts = products.where((p) {
        if (currentPage == 'favorites' && !favorites.contains(p.id)) return false;
        if (searchQuery.isNotEmpty && 
            !p.name.toLowerCase().contains(searchQuery.toLowerCase()) &&
            !p.brand.toLowerCase().contains(searchQuery.toLowerCase())) return false;
        if (selectedBrand != 'All' && p.brand != selectedBrand) return false;
        if (selectedStore != 'All' && p.store != selectedStore) return false;
        if (selectedCategory != 'All' && p.category != selectedCategory) return false;
        if (p.price > maxPrice) return false;
        return true;
      }).toList();

      // Sort
      if (sortBy == 'price-low') {
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
      } else if (sortBy == 'price-high') {
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
      } else if (sortBy == 'rating') {
        filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
      } else {
        filteredProducts.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  void toggleFavorite(String productId) {
    setState(() {
      if (favorites.contains(productId)) {
        favorites.remove(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      } else {
        favorites.add(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      }
      filterProducts();
    });
  }

  void toggleCompare(String productId) {
    setState(() {
      if (compareList.contains(productId)) {
        compareList.remove(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from compare')),
        );
      } else if (compareList.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 4 products can be compared')),
        );
      } else {
        compareList.add(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to compare')),
        );
      }
    });
  }

  List<String> get brands => ['All', ...products.map((p) => p.brand).toSet()];
  List<String> get stores => ['All', ...products.map((p) => p.store).toSet()];
  List<String> get categories => ['All', ...products.map((p) => p.category).toSet()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Egypt Electronics', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                Text('Price Comparison', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${favorites.length}'),
              isLabelVisible: favorites.isNotEmpty,
              child: const Icon(Icons.favorite_border, color: AppColors.textSecondary),
            ),
            onPressed: () {
              setState(() {
                currentPage = currentPage == 'favorites' ? 'home' : 'favorites';
                filterProducts();
              });
            },
          ),
          IconButton(
            icon: Badge(
              label: Text('${compareList.length}'),
              isLabelVisible: compareList.isNotEmpty,
              child: const Icon(Icons.compare_arrows, color: AppColors.textSecondary),
            ),
            onPressed: () {
              if (compareList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompareScreen(
                      products: products.where((p) => compareList.contains(p.id)).toList(),
                      onRemove: toggleCompare,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: scrapeProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocus,
                        style: const TextStyle(color: AppColors.background),
                        decoration: InputDecoration(
                          hintText: 'Search products, brands...',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textMuted),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                      filterProducts();
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            filterProducts();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: showFilters ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                      ),
                      onPressed: () {
                        setState(() => showFilters = !showFilters);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          if (showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedBrand,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          dropdownColor: AppColors.surface,
                          items: brands.map((brand) {
                            return DropdownMenuItem(value: brand, child: Text(brand));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedBrand = value!;
                              filterProducts();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStore,
                          decoration: const InputDecoration(
                            labelText: 'Store',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          dropdownColor: AppColors.surface,
                          items: stores.map((store) {
                            return DropdownMenuItem(value: store, child: Text(store));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStore = value!;
                              filterProducts();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          dropdownColor: AppColors.surface,
                          items: categories.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                              filterProducts();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sortBy,
                          decoration: const InputDecoration(
                            labelText: 'Sort By',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          dropdownColor: AppColors.surface,
                          items: const [
                            DropdownMenuItem(value: 'name', child: Text('Name')),
                            DropdownMenuItem(value: 'price-low', child: Text('Price: Low to High')),
                            DropdownMenuItem(value: 'price-high', child: Text('Price: High to Low')),
                            DropdownMenuItem(value: 'rating', child: Text('Rating')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              sortBy = value!;
                              filterProducts();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max Price: ${maxPrice.toInt()} EGP', 
                        style: const TextStyle(color: AppColors.textSecondary)),
                      Slider(
                        value: maxPrice,
                        min: 0,
                        max: 2000,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            maxPrice = value;
                            filterProducts();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Stats
          if (currentPage == 'home')
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.inventory_2, '${products.length}', 'Products')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(Icons.store, '${stores.length - 1}', 'Stores')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(Icons.trending_up, 
                    '${products.isEmpty ? 0 : (products.map((p) => p.price).reduce((a, b) => a + b) / products.length).toInt()}', 
                    'Avg Price')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(Icons.bolt, 
                    '${products.isEmpty ? 0 : products.map((p) => p.price).reduce((a, b) => a < b ? a : b).toInt()}', 
                    'Best')),
                ],
              ),
            ),

          // Products List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              currentPage == 'favorites' ? 'No favorites yet' : 'No products found',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: viewGrid
                            ? GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return ProductCard(
                                    product: filteredProducts[index],
                                    isFavorite: favorites.contains(filteredProducts[index].id),
                                    isCompare: compareList.contains(filteredProducts[index].id),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            product: filteredProducts[index],
                                            allProducts: products,
                                            favorites: favorites,
                                            compareList: compareList,
                                            onToggleFavorite: toggleFavorite,
                                            onToggleCompare: toggleCompare,
                                          ),
                                        ),
                                      );
                                    },
                                    onToggleFavorite: () => toggleFavorite(filteredProducts[index].id),
                                    onToggleCompare: () => toggleCompare(filteredProducts[index].id),
                                  );
                                },
                              )
                            : ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return ProductListCard(
                                    product: filteredProducts[index],
                                    isFavorite: favorites.contains(filteredProducts[index].id),
                                    isCompare: compareList.contains(filteredProducts[index].id),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            product: filteredProducts[index],
                                            allProducts: products,
                                            favorites: favorites,
                                            compareList: compareList,
                                            onToggleFavorite: toggleFavorite,
                                            onToggleCompare: toggleCompare,
                                          ),
                                        ),
                                      );
                                    },
                                    onToggleFavorite: () => toggleFavorite(filteredProducts[index].id),
                                    onToggleCompare: () => toggleCompare(filteredProducts[index].id),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: Icon(viewGrid ? Icons.list : Icons.grid_view),
        onPressed: () {
          setState(() => viewGrid = !viewGrid);
        },
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final bool isCompare;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleCompare;

  const ProductCard({
    Key? key,
    required this.product,
    required this.isFavorite,
    required this.isCompare,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onToggleCompare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: product.image != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            product.image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported, color: AppColors.textMuted, size: 40),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.inventory_2, color: AppColors.textMuted, size: 40),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFavorite ? AppColors.primary : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.white : AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onToggleCompare,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isCompare ? Colors.blue : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.compare_arrows,
                            color: isCompare ? Colors.white : AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (product.availability == 'In Stock')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('In Stock', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(product.brand, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price.toInt()} EGP',
                          style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(product.rating.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(product.store, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
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

class ProductListCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final bool isCompare;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleCompare;

  const ProductListCard({
    Key? key,
    required this.product,
    required this.isFavorite,
    required this.isCompare,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onToggleCompare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : const Center(child: Icon(Icons.inventory_2, color: AppColors.textMuted, size: 40)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFavorite ? AppColors.primary : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.white : AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onToggleCompare,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isCompare ? Colors.blue : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.compare_arrows,
                            color: isCompare ? Colors.white : AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(product.brand, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${product.price.toInt()} EGP',
                        style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(product.rating.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(product.store, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  if (product.availability == 'In Stock')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('In Stock', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
