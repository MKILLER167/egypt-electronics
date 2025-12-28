import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const EgyptElectronicsApp());

class AppColors {
  static const background = Color(0xFF0a0a0a);
  static const surface = Color(0xFF2a2a2a);
  static const surfaceLight = Color(0xFF333333);
  static const border = Color(0xFF444444);
  static const primary = Color(0xFFff6b35);
  static const primaryDark = Color(0xFFf7931e);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF999999);
  static const textMuted = Color(0xFF666666);
  static const inputBg = Color(0xFF222222);
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String store;
  final String category;
  final double price;
  final double rating;
  final String availability;
  final String? image;
  int views;
  int likes;

  Product({
    required this.id, required this.name, required this.brand,
    required this.store, required this.category, required this.price,
    required this.rating, required this.availability, this.image,
    this.views = 0, this.likes = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'].toString(), name: json['name'] ?? '',
    brand: json['brand'] ?? '', store: json['store'] ?? '',
    category: json['category'] ?? '', price: (json['price'] ?? 0).toDouble(),
    rating: (json['rating'] ?? 0).toDouble(),
    availability: json['availability'] ?? 'Out of Stock',
    image: json['image'], views: json['views'] ?? 0, likes: json['likes'] ?? 0,
  );
}

class EgyptElectronicsApp extends StatelessWidget {
  const EgyptElectronicsApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Egypt Electronics', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary, appBarTheme: const AppBarTheme(backgroundColor: AppColors.surface, elevation: 0),
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Product> products = [], filteredProducts = [];
  List<String> favorites = [], compareList = [], recentlyViewed = [];
  String searchQuery = '', selectedBrand = 'All', selectedStore = 'All', selectedCategory = 'All', sortBy = 'name', currentPage = 'home';
  double maxPrice = 2000;
  bool showFilters = false, isLoading = true, viewGrid = true, showNotifications = false;
  int notificationCount = 3;
  late TabController _tabController;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/products'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          filterProducts();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnack('Failed to load products');
    }
  }

  void filterProducts() {
    setState(() {
      filteredProducts = products.where((p) {
        if (currentPage == 'favorites' && !favorites.contains(p.id)) return false;
        if (currentPage == 'deals' && p.price > 500) return false;
        if (searchQuery.isNotEmpty && !p.name.toLowerCase().contains(searchQuery.toLowerCase()) && !p.brand.toLowerCase().contains(searchQuery.toLowerCase())) return false;
        if (selectedBrand != 'All' && p.brand != selectedBrand) return false;
        if (selectedStore != 'All' && p.store != selectedStore) return false;
        if (selectedCategory != 'All' && p.category != selectedCategory) return false;
        if (p.price > maxPrice) return false;
        return true;
      }).toList();

      if (sortBy == 'price-low') filteredProducts.sort((a, b) => a.price.compareTo(b.price));
      else if (sortBy == 'price-high') filteredProducts.sort((a, b) => b.price.compareTo(a.price));
      else if (sortBy == 'rating') filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
      else if (sortBy == 'popular') filteredProducts.sort((a, b) => b.views.compareTo(a.views));
      else filteredProducts.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void toggleFavorite(String id) => setState(() {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    _showSnack(favorites.contains(id) ? 'Added to favorites' : 'Removed from favorites');
    filterProducts();
  });

  void toggleCompare(String id) => setState(() {
    if (compareList.contains(id)) compareList.remove(id);
    else if (compareList.length >= 4) _showSnack('Maximum 4 products');
    else compareList.add(id);
  });

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.surface, behavior: SnackBarBehavior.floating));

  List<String> get brands => ['All', ...products.map((p) => p.brand).toSet()];
  List<String> get stores => ['All', ...products.map((p) => p.store).toSet()];
  List<String> get categories => ['All', ...products.map((p) => p.category).toSet()];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_bag, size: 24)),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Egypt Electronics', style: TextStyle(fontSize: 16)),
          Text('Price Comparison', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
      actions: [
        Stack(children: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => setState(() => showNotifications = !showNotifications)),
          if (notificationCount > 0) Positioned(right: 8, top: 8, child: Container(
            padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: Text('$notificationCount', style: const TextStyle(fontSize: 10), textAlign: TextAlign.center))),
        ]),
        IconButton(icon: const Icon(Icons.share), onPressed: () => _showSnack('Share app')),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => _showSnack('Settings')),
      ],
      bottom: TabBar(controller: _tabController, isScrollable: true, indicatorColor: AppColors.primary,
        labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary,
        onTap: (i) => setState(() {
          currentPage = ['home', 'favorites', 'compare', 'deals', 'analytics'][i];
          filterProducts();
        }),
        tabs: [
          const Tab(icon: Icon(Icons.home), text: 'Home'),
          Tab(icon: Badge(label: Text('${favorites.length}'), isLabelVisible: favorites.isNotEmpty,
            child: const Icon(Icons.favorite_border)), text: 'Favorites'),
          Tab(icon: Badge(label: Text('${compareList.length}'), isLabelVisible: compareList.isNotEmpty,
            child: const Icon(Icons.compare_arrows)), text: 'Compare'),
          const Tab(icon: Icon(Icons.local_offer), text: 'Deals'),
          const Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
        ]),
    ),
    body: Column(children: [
      if (showNotifications) Container(color: AppColors.surface, padding: const EdgeInsets.all(16),
        child: Column(children: [
          _notifItem(Icons.local_offer, 'New deal on Samsung!', '2h ago'),
          _notifItem(Icons.trending_down, 'Price drop on iPhone', '5h ago'),
          _notifItem(Icons.check_circle, 'Back in stock', '1d ago'),
        ])),
      
      Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])),
        child: Row(children: [
          Expanded(child: TextField(controller: searchController, style: const TextStyle(color: AppColors.background),
            decoration: InputDecoration(hintText: 'Search...', hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear),
                onPressed: () => setState(() { searchController.clear(); searchQuery = ''; filterProducts(); }))
                : IconButton(icon: const Icon(Icons.mic), onPressed: () => _showSnack('Voice search soon!')),
              filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            onChanged: (v) => setState(() { searchQuery = v; filterProducts(); }))),
          const SizedBox(width: 8),
          IconButton(icon: Icon(showFilters ? Icons.filter_alt : Icons.filter_alt_outlined, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
            onPressed: () => setState(() => showFilters = !showFilters)),
        ])),

      if (showFilters) Container(padding: const EdgeInsets.all(16), color: AppColors.surface,
        child: Column(children: [
          Row(children: [
            Expanded(child: _dropdown('Brand', selectedBrand, brands, (v) => setState(() { selectedBrand = v!; filterProducts(); }))),
            const SizedBox(width: 8),
            Expanded(child: _dropdown('Store', selectedStore, stores, (v) => setState(() { selectedStore = v!; filterProducts(); }))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dropdown('Category', selectedCategory, categories, (v) => setState(() { selectedCategory = v!; filterProducts(); }))),
            const SizedBox(width: 8),
            Expanded(child: _dropdown('Sort', sortBy, ['name', 'price-low', 'price-high', 'rating', 'popular'],
              (v) => setState(() { sortBy = v!; filterProducts(); }), labels: ['Name', 'Price ↑', 'Price ↓', 'Rating', 'Popular'])),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Max Price: ${maxPrice.toInt()} EGP', style: const TextStyle(color: AppColors.textSecondary)),
            Slider(value: maxPrice, min: 0, max: 2000, divisions: 40, activeColor: AppColors.primary,
              onChanged: (v) => setState(() { maxPrice = v; filterProducts(); })),
          ]),
        ])),

      if (currentPage == 'analytics') Expanded(child: _analyticsView())
      else if (currentPage == 'compare' && compareList.isNotEmpty) Expanded(child: _compareView())
      else Expanded(child: Column(children: [
        if (currentPage == 'home') Padding(padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: _statCard(Icons.inventory_2, '${products.length}', 'Products')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.store, '${stores.length - 1}', 'Stores')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.trending_up,
              '${products.isEmpty ? 0 : (products.map((p) => p.price).reduce((a, b) => a + b) / products.length).toInt()}', 'Avg')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.bolt,
              '${products.isEmpty ? 0 : products.map((p) => p.price).reduce((a, b) => a < b ? a : b).toInt()}', 'Best')),
          ])),

        if (currentPage == 'home' && recentlyViewed.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recently Viewed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => setState(() => recentlyViewed.clear()),
                child: const Text('Clear', style: TextStyle(color: AppColors.primary))),
            ]),
            SizedBox(height: 140, child: ListView.builder(scrollDirection: Axis.horizontal,
              itemCount: recentlyViewed.take(5).length,
              itemBuilder: (ctx, i) {
                final p = products.firstWhere((p) => p.id == recentlyViewed[i], orElse: () => products.first);
                return _recentCard(p);
              })),
            const SizedBox(height: 16),
          ])),

        Expanded(child: isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : filteredProducts.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(currentPage == 'favorites' ? 'No favorites' : currentPage == 'deals' ? 'No deals' : 'No products',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 18)),
            ]))
          : Padding(padding: const EdgeInsets.all(16),
            child: viewGrid ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,
                childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, i) => ProductCard(product: filteredProducts[i],
                isFavorite: favorites.contains(filteredProducts[i].id),
                isCompare: compareList.contains(filteredProducts[i].id),
                onTap: () { recentlyViewed.remove(filteredProducts[i].id); recentlyViewed.insert(0, filteredProducts[i].id);
                  Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductDetail(product: filteredProducts[i],
                    onFav: toggleFavorite, onCompare: toggleCompare))); },
                onFav: () => toggleFavorite(filteredProducts[i].id),
                onCompare: () => toggleCompare(filteredProducts[i].id)))
            : ListView.builder(itemCount: filteredProducts.length,
              itemBuilder: (ctx, i) => ProductListCard(product: filteredProducts[i],
                isFavorite: favorites.contains(filteredProducts[i].id),
                isCompare: compareList.contains(filteredProducts[i].id),
                onTap: () { recentlyViewed.remove(filteredProducts[i].id); recentlyViewed.insert(0, filteredProducts[i].id);
                  Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductDetail(product: filteredProducts[i],
                    onFav: toggleFavorite, onCompare: toggleCompare))); },
                onFav: () => toggleFavorite(filteredProducts[i].id),
                onCompare: () => toggleCompare(filteredProducts[i].id))))),
      ])),
    ]),
    floatingActionButton: currentPage != 'analytics' && currentPage != 'compare' ? FloatingActionButton(
      backgroundColor: AppColors.primary, child: Icon(viewGrid ? Icons.list : Icons.grid_view),
      onPressed: () => setState(() => viewGrid = !viewGrid)) : null,
  );

  Widget _notifItem(IconData icon, String title, String time) => ListTile(
    leading: Icon(icon, color: AppColors.primary), title: Text(title), subtitle: Text(time,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)), contentPadding: EdgeInsets.zero);

  Widget _dropdown(String label, String value, List<String> items, Function(String?) onChanged, {List<String>? labels}) =>
    DropdownButtonFormField<String>(value: value,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      dropdownColor: AppColors.surface,
      items: items.asMap().entries.map((e) => DropdownMenuItem(value: e.value,
        child: Text(labels != null && labels.length > e.key ? labels[e.key] : e.value))).toList(),
      onChanged: onChanged);

  Widget _statCard(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surface,
      borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
    ]));

  Widget _recentCard(Product p) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetail(product: p,
      onFav: toggleFavorite, onCompare: toggleCompare))),
    child: Container(width: 100, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Container(height: 80, decoration: BoxDecoration(color: AppColors.inputBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: p.image != null ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(p.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.image_not_supported, color: AppColors.textMuted))))
            : const Center(child: Icon(Icons.inventory_2, color: AppColors.textMuted, size: 30))),
        Padding(padding: const EdgeInsets.all(8), child: Column(children: [
          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          Text('${p.price.toInt()} EGP', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
        ])),
      ])));

  Widget _analyticsView() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
    const Text('Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    _analyticsCard('Products Viewed', '${recentlyViewed.length}', Icons.visibility, Colors.blue),
    _analyticsCard('Favorites', '${favorites.length}', Icons.favorite, Colors.red),
    _analyticsCard('Compared', '${compareList.length}', Icons.compare_arrows, Colors.green),
    _analyticsCard('Total Products', '${products.length}', Icons.inventory, Colors.orange),
  ]));

  Widget _analyticsCard(String title, String value, IconData icon, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 24)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(title, style: const TextStyle(color: AppColors.textSecondary)),
      ])),
    ]));

  Widget _compareView() => ListView.builder(padding: const EdgeInsets.all(16),
    itemCount: compareList.length,
    itemBuilder: (ctx, i) {
      final p = products.firstWhere((p) => p.id == compareList[i]);
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Row(children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(8)),
              child: p.image != null ? ClipRRect(borderRadius: BorderRadius.circular(8),
                child: Image.network(p.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.image_not_supported))))
                : const Center(child: Icon(Icons.inventory_2, size: 30))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${p.price.toInt()} EGP', style: const TextStyle(color: AppColors.primary, fontSize: 18)),
            ])),
            IconButton(icon: const Icon(Icons.close), onPressed: () => toggleCompare(p.id)),
          ]),
          const Divider(color: AppColors.border),
          _compareRow('Brand', p.brand),
          _compareRow('Store', p.store),
          _compareRow('Rating', '${p.rating} ⭐'),
          _compareRow('Status', p.availability),
        ]));
    });

  Widget _compareRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]));
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite, isCompare;
  final VoidCallback onTap, onFav, onCompare;

  const ProductCard({Key? key, required this.product, required this.isFavorite, required this.isCompare,
    required this.onTap, required this.onFav, required this.onCompare}) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(height: 140, decoration: BoxDecoration(color: AppColors.inputBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: product.image != null ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(product.image!, fit: BoxFit.cover, width: double.infinity,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, size: 40))))
              : const Center(child: Icon(Icons.inventory_2, size: 40))),
          Positioned(top: 8, left: 8, child: Row(children: [
            GestureDetector(onTap: onFav, child: Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: isFavorite ? AppColors.primary : Colors.white.withOpacity(0.9),
                shape: BoxShape.circle),
              child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.white : AppColors.textMuted, size: 16))),
            const SizedBox(width: 4),
            GestureDetector(onTap: onCompare, child: Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: isCompare ? Colors.blue : Colors.white.withOpacity(0.9),
                shape: BoxShape.circle),
              child: Icon(Icons.compare_arrows, color: isCompare ? Colors.white : AppColors.textMuted, size: 16))),
          ])),
          if (product.availability == 'In Stock') Positioned(top: 8, right: 8,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
              child: const Text('In Stock', style: TextStyle(fontSize: 10)))),
        ]),
        Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(product.brand, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${product.price.toInt()} EGP',
                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text('${product.rating}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 4),
            Text(product.store, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]))),
      ])));
}

class ProductListCard extends StatelessWidget {
  final Product product;
  final bool isFavorite, isCompare;
  final VoidCallback onTap, onFav, onCompare;

  const ProductListCard({Key? key, required this.product, required this.isFavorite, required this.isCompare,
    required this.onTap, required this.onFav, required this.onCompare}) : super(key: key);

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
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.inventory_2, size: 40),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.brand,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toInt()} EGP',
                    style: const TextStyle(color: AppColors.primary, fontSize: 18),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onFav,
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onCompare,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isCompare ? AppColors.primary : Colors.white.withOpacity(0.9),
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
                ],
              ),
            ),
            if (product.availability == 'In Stock')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'In Stock',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductDetail extends StatelessWidget {
  final Product product;
  final Function(String) onFav, onCompare;

  const ProductDetail({Key? key, required this.product, required this.onFav, required this.onCompare}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(product.name),
      actions: [
        IconButton(icon: const Icon(Icons.favorite_border), onPressed: () => onFav(product.id)),
        IconButton(icon: const Icon(Icons.compare_arrows), onPressed: () => onCompare(product.id)),
      ],
    ),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 200, decoration: BoxDecoration(color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(12)),
          child: product.image != null ? ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.network(product.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.image_not_supported, size: 80))))
            : const Center(child: Icon(Icons.inventory_2, size: 80))),
        const SizedBox(height: 16),
        Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('${product.price.toInt()} EGP', style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          ...List.generate(5, (i) => Icon(i < product.rating.floor() ? Icons.star : Icons.star_border,
            color: Colors.amber, size: 20)),
          const SizedBox(width: 8),
          Text('${product.rating}/5.0', style: const TextStyle(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
          child: Column(children: [
            _detailRow('Brand', product.brand),
            _detailRow('Store', product.store),
            _detailRow('Category', product.category),
            _detailRow('Availability', product.availability),
          ])),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16)),
          onPressed: () => _showSnack(context, 'Redirecting to store...'),
          child: const Text('View at Store', style: TextStyle(fontSize: 16)))),
      ])),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.shopping_cart),
      onPressed: () => _showSnack(context, 'Added to cart')),
  );

  void _showSnack(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.surface, behavior: SnackBarBehavior.floating));

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]));
}