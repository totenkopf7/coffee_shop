/// A menu item.
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imageUrl;
  final bool isAvailable;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
      isAvailable: (map['is_available'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'is_available': isAvailable,
      };

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  @override
  String toString() => 'Product(#$id, $name, $price)';
}