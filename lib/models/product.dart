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

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.store,
    required this.category,
    required this.price,
    required this.rating,
    required this.availability,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      store: json['store'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      availability: json['availability'] ?? 'Unknown',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'store': store,
      'category': category,
      'price': price,
      'rating': rating,
      'availability': availability,
      'image': image,
    };
  }
}
