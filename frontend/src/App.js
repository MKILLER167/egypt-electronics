import React, { useState, useEffect, useMemo, useRef } from 'react';
import { Search, RefreshCw, Filter, ShoppingCart, Star, Store, ChevronLeft, TrendingDown, Package, X, Home } from 'lucide-react';

const API_URL = 'http://127.0.0.1:8000';

function App() {
  const [products, setProducts] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBrand, setSelectedBrand] = useState('All');
  const [selectedStore, setSelectedStore] = useState('All');
  const [priceRange, setPriceRange] = useState([0, 2000]);
  const [sortBy, setSortBy] = useState('name');
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  
  const dropdownRef = useRef(null);
  const searchRef = useRef(null);

  useEffect(() => {
    fetch(`${API_URL}/api/products`)
      .then(res => res.json())
      .then(data => setProducts(data))
      .catch(err => console.error('Error loading products:', err));
  }, []);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleScrape = async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_URL}/api/scrape`, { method: 'POST' });
      await response.json();

      setTimeout(async () => {
        try {
          const productsRes = await fetch(`${API_URL}/api/products`);
          const productsData = await productsRes.json();
          setProducts(productsData);
          setIsLoading(false);
          alert(`✅ Loaded ${productsData.length} products!`);
        } catch (error) {
          console.error('Error reloading products:', error);
          setIsLoading(false);
          alert('❌ Error loading products');
        }
      }, 3000);
    } catch (error) {
      console.error('Scraping error:', error);
      setIsLoading(false);
      alert('❌ Error scraping products');
    }
  };

  // Real-time search dropdown suggestions
  const dropdownSuggestions = useMemo(() => {
    if (!searchQuery.trim()) return [];
    
    const query = searchQuery.toLowerCase();
    return products
      .filter(p =>
        p.name.toLowerCase().includes(query) ||
        p.brand.toLowerCase().includes(query) ||
        p.store.toLowerCase().includes(query)
      )
      .slice(0, 8);
  }, [products, searchQuery]);

  // Show dropdown whenever there's a search query and results
  useEffect(() => {
    if (searchQuery.trim() && dropdownSuggestions.length > 0) {
      setShowDropdown(true);
    } else {
      setShowDropdown(false);
    }
  }, [searchQuery, dropdownSuggestions.length]);

  const filteredProducts = useMemo(() => {
    let filtered = products;

    if (searchQuery) {
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.brand.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    if (selectedBrand !== 'All') {
      filtered = filtered.filter(p => p.brand === selectedBrand);
    }

    if (selectedStore !== 'All') {
      filtered = filtered.filter(p => p.store === selectedStore);
    }

    filtered = filtered.filter(p => p.price >= priceRange[0] && p.price <= priceRange[1]);

    const sorted = [...filtered].sort((a, b) => {
      if (sortBy === 'price-low') return a.price - b.price;
      if (sortBy === 'price-high') return b.price - a.price;
      if (sortBy === 'rating') return b.rating - a.rating;
      return a.name.localeCompare(b.name);
    });

    return sorted;
  }, [products, searchQuery, selectedBrand, selectedStore, priceRange, sortBy]);

  const handleKeyDown = (e) => {
    switch (e.key) {
      case 'ArrowDown':
        if (showDropdown && dropdownSuggestions.length > 0) {
          e.preventDefault();
          setSelectedIndex(prev => 
            prev < dropdownSuggestions.length - 1 ? prev + 1 : prev
          );
        }
        break;
      case 'ArrowUp':
        if (showDropdown && dropdownSuggestions.length > 0) {
          e.preventDefault();
          setSelectedIndex(prev => prev > 0 ? prev - 1 : -1);
        }
        break;
      case 'Enter':
        e.preventDefault();
        if (showDropdown && dropdownSuggestions.length > 0 && selectedIndex >= 0) {
          // Select from dropdown
          handleProductSelect(dropdownSuggestions[selectedIndex]);
        } else if (searchQuery.trim()) {
          // Search with Enter key - find first matching product
          const firstMatch = filteredProducts[0];
          if (firstMatch) {
            setSelectedProduct(firstMatch);
          }
        }
        break;
      case 'Escape':
        setShowDropdown(false);
        setSelectedIndex(-1);
        break;
      default:
        break;
    }
  };

  const handleProductSelect = (product) => {
    setSearchQuery(product.name);
    setShowDropdown(false);
    setSelectedIndex(-1);
    setSelectedProduct(product);
  };

  const clearSearch = () => {
    setSearchQuery('');
    setShowDropdown(false);
    setSelectedIndex(-1);
    searchRef.current?.focus();
  };

  const handleBackToHome = () => {
    setSelectedProduct(null);
    setSearchQuery('');
    setSelectedBrand('All');
    setSelectedStore('All');
    setPriceRange([0, 2000]);
    setSortBy('name');
  };

  const brands = ['All', ...new Set(products.map(p => p.brand))];
  const stores = ['All', ...new Set(products.map(p => p.store))];

  const stats = {
    totalProducts: products.length,
    totalStores: stores.length - 1,
    avgPrice: Math.round(products.reduce((sum, p) => sum + p.price, 0) / products.length) || 0,
    lowestPrice: products.length > 0 ? Math.min(...products.map(p => p.price)) : 0
  };

  if (selectedProduct) {
    return (
      <ProductDetailView 
        product={selectedProduct} 
        onBack={() => setSelectedProduct(null)}
        onHome={handleBackToHome}
        allProducts={products}
        setSelectedProduct={setSelectedProduct}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Simple Header */}
      <header className="bg-white border-b-2 border-gray-200 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <Package className="w-8 h-8 text-red-600" />
              <div>
                <h1 className="text-xl font-bold text-gray-900">Egypt Electronics</h1>
                <p className="text-xs text-gray-500">Price Comparison</p>
              </div>
            </div>
            <button
              onClick={handleScrape}
              disabled={isLoading}
              className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded font-medium disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 inline mr-2 ${isLoading ? 'animate-spin' : ''}`} />
              {isLoading ? 'Loading...' : 'Update'}
            </button>
          </div>

          {/* Search Bar with Real-time Dropdown */}
          <div className="flex gap-2">
            <div className="flex-1 relative" ref={dropdownRef}>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  ref={searchRef}
                  type="text"
                  value={searchQuery}
                  onChange={(e) => {
                    setSearchQuery(e.target.value);
                    setSelectedIndex(-1);
                  }}
                  onKeyDown={handleKeyDown}
                  placeholder="Search products..."
                  className="w-full bg-white border border-gray-300 rounded pl-10 pr-10 py-2 focus:border-red-500 focus:outline-none"
                />
                {searchQuery && (
                  <button
                    onClick={clearSearch}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>

              {/* Real-time Dropdown */}
              {showDropdown && dropdownSuggestions.length > 0 && (
                <div className="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded shadow-lg max-h-80 overflow-y-auto">
                  {dropdownSuggestions.map((product, index) => (
                    <div
                      key={product.id}
                      onClick={() => handleProductSelect(product)}
                      className={`flex items-center gap-3 p-3 cursor-pointer border-b border-gray-100 last:border-b-0 ${
                        index === selectedIndex ? 'bg-gray-100' : 'hover:bg-gray-50'
                      }`}
                    >
                      <div className="w-10 h-10 bg-gray-100 rounded flex-shrink-0 overflow-hidden">
                        {product.image ? (
                          <img
                            src={product.image}
                            alt={product.name}
                            className="w-full h-full object-cover"
                            onError={(e) => e.target.style.display = 'none'}
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center">
                            <Package className="w-4 h-4 text-gray-400" />
                          </div>
                        )}
                      </div>

                      <div className="flex-1 min-w-0">
                        <h3 className="text-sm font-medium text-gray-900 truncate">
                          {product.name}
                        </h3>
                        <div className="flex items-center gap-2 text-xs text-gray-500">
                          <span>{product.brand}</span>
                          <span>•</span>
                          <span>{product.store}</span>
                        </div>
                      </div>

                      <div className="text-right flex-shrink-0">
                        <div className="text-sm font-bold text-red-600">
                          {product.price} EGP
                        </div>
                        <div className="flex items-center gap-1 text-xs text-gray-500">
                          <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                          <span>{product.rating}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`${showFilters ? 'bg-red-600 text-white' : 'bg-white text-gray-700'} border border-gray-300 hover:bg-red-600 hover:text-white px-4 rounded font-medium`}
            >
              <Filter className="w-4 h-4 inline mr-2" />
              Filters
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 py-6">
        {/* Simple Statistics */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white border border-gray-200 rounded p-4 text-center">
            <div className="text-2xl font-bold text-red-600">{stats.totalProducts}</div>
            <div className="text-xs text-gray-600">Products</div>
          </div>
          <div className="bg-white border border-gray-200 rounded p-4 text-center">
            <div className="text-2xl font-bold text-red-600">{stats.totalStores}</div>
            <div className="text-xs text-gray-600">Stores</div>
          </div>
          <div className="bg-white border border-gray-200 rounded p-4 text-center">
            <div className="text-2xl font-bold text-red-600">{stats.avgPrice}</div>
            <div className="text-xs text-gray-600">Avg Price (EGP)</div>
          </div>
          <div className="bg-white border border-gray-200 rounded p-4 text-center">
            <div className="text-2xl font-bold text-red-600">{stats.lowestPrice}</div>
            <div className="text-xs text-gray-600">Lowest (EGP)</div>
          </div>
        </div>

        {/* Filters Panel */}
        {showFilters && (
          <div className="bg-white border border-gray-200 rounded p-4 mb-6 grid md:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Brand</label>
              <select
                value={selectedBrand}
                onChange={(e) => setSelectedBrand(e.target.value)}
                className="w-full bg-white border border-gray-300 rounded px-3 py-2 text-sm focus:border-red-500 focus:outline-none"
              >
                {brands.map(brand => <option key={brand}>{brand}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Store</label>
              <select
                value={selectedStore}
                onChange={(e) => setSelectedStore(e.target.value)}
                className="w-full bg-white border border-gray-300 rounded px-3 py-2 text-sm focus:border-red-500 focus:outline-none"
              >
                {stores.map(store => <option key={store}>{store}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Sort By</label>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="w-full bg-white border border-gray-300 rounded px-3 py-2 text-sm focus:border-red-500 focus:outline-none"
              >
                <option value="name">Name</option>
                <option value="price-low">Price: Low to High</option>
                <option value="price-high">Price: High to Low</option>
                <option value="rating">Rating</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Max Price: {priceRange[1]} EGP</label>
              <input
                type="range"
                min="0"
                max="2000"
                value={priceRange[1]}
                onChange={(e) => setPriceRange([0, parseInt(e.target.value)])}
                className="w-full accent-red-600"
              />
            </div>
          </div>
        )}

        {/* Results Count */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-base font-semibold text-gray-900">
            {filteredProducts.length} Products Found
          </h2>
          {searchQuery && (
            <span className="text-sm text-gray-500">Results for "{searchQuery}"</span>
          )}
        </div>

        {/* Products Grid */}
        {filteredProducts.length > 0 ? (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredProducts.map(product => (
              <ProductCard key={product.id} product={product} onClick={() => setSelectedProduct(product)} />
            ))}
          </div>
        ) : (
          <div className="text-center py-20 bg-white rounded border border-gray-200">
            <Package className="w-16 h-16 mx-auto text-gray-300 mb-4" />
            <h3 className="text-lg text-gray-600 mb-2">No products found</h3>
            <p className="text-gray-400">Try adjusting your filters</p>
          </div>
        )}
      </div>
    </div>
  );
}

function ProductCard({ product, onClick }) {
  const [imageError, setImageError] = useState(false);

  return (
    <div
      onClick={onClick}
      className="bg-white border border-gray-200 rounded overflow-hidden hover:border-red-500 hover:shadow-md transition-all cursor-pointer"
    >
      <div className="relative h-40 bg-gray-100">
        {!imageError && product.image ? (
          <img 
            src={product.image} 
            alt={product.name} 
            className="w-full h-full object-cover"
            onError={() => setImageError(true)}
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gray-100">
            <Package className="w-8 h-8 text-gray-400" />
          </div>
        )}
        {product.availability === 'In Stock' && (
          <span className="absolute top-2 right-2 bg-green-500 text-white text-xs px-2 py-1 rounded">In Stock</span>
        )}
      </div>
      <div className="p-4">
        <h3 className="font-medium text-gray-900 mb-2 line-clamp-2 min-h-[40px] text-sm">{product.name}</h3>
        <p className="text-xs text-gray-500 mb-2">{product.brand}</p>
        <div className="flex items-center justify-between mb-2">
          <span className="text-xl font-bold text-red-600">{product.price} EGP</span>
          <div className="flex items-center gap-1">
            <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
            <span className="text-sm text-gray-600">{product.rating}</span>
          </div>
        </div>
        <div className="flex items-center justify-between text-xs text-gray-500">
          <span className="flex items-center gap-1">
            <Store className="w-3 h-3" />
            {product.store}
          </span>
          <span>{product.category}</span>
        </div>
      </div>
    </div>
  );
}

function ProductDetailView({ product, onBack, onHome, allProducts, setSelectedProduct }) {
  const [imageError, setImageError] = useState(false);
  const similarProducts = allProducts
    .filter(p => p.id !== product.id && (p.category === product.category || p.brand === product.brand))
    .slice(0, 3);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Simple Header */}
      <header className="bg-white border-b-2 border-gray-200 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Package className="w-8 h-8 text-red-600" />
              <div>
                <h1 className="text-xl font-bold text-gray-900">Egypt Electronics</h1>
                <p className="text-xs text-gray-500">Price Comparison</p>
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => {
                  console.log('Back button clicked');
                  onBack();
                }}
                className="bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 px-4 py-2 rounded font-medium"
              >
                <ChevronLeft className="w-4 h-4 inline mr-1" />
                Back
              </button>
              <button
                onClick={() => {
                  console.log('Home button clicked');
                  onHome();
                }}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded font-medium"
              >
                <Home className="w-4 h-4 inline mr-1" />
                Home
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto px-4 py-8">
        <div className="grid md:grid-cols-2 gap-8 mb-12">
          <div className="bg-white border border-gray-200 rounded overflow-hidden">
            {!imageError && product.image ? (
              <img 
                src={product.image} 
                alt={product.name} 
                className="w-full h-96 object-cover"
                onError={() => setImageError(true)}
              />
            ) : (
              <div className="w-full h-96 flex items-center justify-center bg-gray-100">
                <Package className="w-16 h-16 text-gray-400" />
              </div>
            )}
          </div>

          <div>
            <h1 className="text-2xl font-bold text-gray-900 mb-4">{product.name}</h1>
            <div className="flex items-center gap-4 mb-6">
              <div className="flex items-center gap-1">
                {[...Array(5)].map((_, i) => (
                  <Star
                    key={i}
                    className={`w-5 h-5 ${i < Math.floor(product.rating) ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}`}
                  />
                ))}
                <span className="ml-2 text-gray-600 font-medium">{product.rating}/5.0</span>
              </div>
              <span className="bg-green-500 text-white text-xs px-3 py-1 rounded">{product.availability}</span>
            </div>

            <div className="bg-white border border-gray-200 rounded p-6 mb-6">
              <div className="grid grid-cols-2 gap-4 mb-6">
                <div>
                  <p className="text-gray-600 text-sm mb-1">Brand</p>
                  <p className="font-medium text-gray-900">{product.brand}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm mb-1">Category</p>
                  <p className="font-medium text-gray-900">{product.category}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm mb-1">Store</p>
                  <p className="font-medium text-gray-900">{product.store}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm mb-1">Availability</p>
                  <p className="font-medium text-gray-900">{product.availability}</p>
                </div>
              </div>

              <div className="border-t border-gray-200 pt-6">
                <p className="text-3xl font-bold text-red-600 mb-4">{product.price} EGP</p>
                <button className="w-full bg-red-600 hover:bg-red-700 text-white py-3 rounded font-medium">
                  <ShoppingCart className="w-5 h-5 inline mr-2" />
                  View at Store
                </button>
              </div>
            </div>

            <div className="bg-white border border-gray-200 rounded p-6">
              <h3 className="font-semibold text-gray-900 mb-3">Product Description</h3>
              <p className="text-gray-600 text-sm leading-relaxed">
                High-quality {product.name.toLowerCase()} available at {product.store}. Perfect for your electronics projects and prototyping needs.
              </p>
            </div>
          </div>
        </div>

        {similarProducts.length > 0 && (
          <div>
            <h2 className="text-xl font-bold text-gray-900 mb-6">Similar Products</h2>
            <div className="grid md:grid-cols-3 gap-4">
              {similarProducts.map(p => (
                <ProductCard key={p.id} product={p} onClick={() => setSelectedProduct(p)} />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;