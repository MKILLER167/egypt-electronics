import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  final String _baseUrl = 'http://127.0.0.1:8000';
  
  List<Product> _products = [];
  List<Product> get products => _products;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isInitialLoading = true;
  bool get isInitialLoading => _isInitialLoading;
  
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  
  String _selectedBrand = 'All';
  String get selectedBrand => _selectedBrand;
  
  String _selectedStore = 'All';
  String get selectedStore => _selectedStore;
  
  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;
  
  RangeValues _priceRange = const RangeValues(0, 2000);
  RangeValues get priceRange => _priceRange;
  
  String _sortBy = 'name';
  String get sortBy => _sortBy;
  
  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;
  
  List<String> _favorites = [];
  List<String> get favorites => _favorites;
  
  List<String> _compareList = [];
  List<String> get compareList => _compareList;
  
  List<String> _recentlyViewed = [];
  List<String> get recentlyViewed => _recentlyViewed;

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _products = data.map((json) => Product.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> scrapeProducts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(Uri.parse('$_baseUrl/api/scrape'));
      if (response.statusCode == 200) {
        await Future.delayed(const Duration(seconds: 3));
        await fetchProducts();
      }
    } catch (e) {
      print('Error scraping products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Product> get filteredProducts {
    List<Product> filtered = List.from(_products);
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.brand.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedBrand != 'All') {
      filtered = filtered.where((p) => p.brand == _selectedBrand).toList();
    }
    
    if (_selectedStore != 'All') {
      filtered = filtered.where((p) => p.store == _selectedStore).toList();
    }
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    filtered = filtered.where((p) => 
      p.price >= _priceRange.start && p.price <= _priceRange.end
    ).toList();
    
    switch (_sortBy) {
      case 'price-low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price-high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return filtered;
  }

  List<String> get brands {
    final allBrands = _products.map((p) => p.brand).toSet().toList();
    allBrands.sort();
    return ['All', ...allBrands];
  }

  List<String> get stores {
    final allStores = _products.map((p) => p.store).toSet().toList();
    allStores.sort();
    return ['All', ...allStores];
  }

  List<String> get categories {
    final allCategories = _products.map((p) => p.category).toSet().toList();
    allCategories.sort();
    return ['All', ...allCategories];
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateSelectedBrand(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void updateSelectedStore(String store) {
    _selectedStore = store;
    notifyListeners();
  }

  void updateSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updatePriceRange(RangeValues range) {
    _priceRange = range;
    notifyListeners();
  }

  void updateSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    _recentlyViewed.remove(product.id);
    _recentlyViewed.insert(0, product.id);
    if (_recentlyViewed.length > 10) {
      _recentlyViewed = _recentlyViewed.take(10).toList();
    }
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  void toggleFavorite(String productId) {
    if (_favorites.contains(productId)) {
      _favorites.remove(productId);
    } else {
      _favorites.add(productId);
    }
    notifyListeners();
  }

  void toggleCompare(String productId) {
    if (_compareList.contains(productId)) {
      _compareList.remove(productId);
    } else if (_compareList.length < 4) {
      _compareList.add(productId);
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedBrand = 'All';
    _selectedStore = 'All';
    _selectedCategory = 'All';
    _priceRange = const RangeValues(0, 2000);
    _sortBy = 'name';
    notifyListeners();
  }
}
