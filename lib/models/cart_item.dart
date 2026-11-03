import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() => {
        'product_id': product.id,
        'name': product.name,
        'price': product.price,
        'image_url': product.imageUrl,
        'category': product.category,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product(
        id: (json['product_id'] as num).toInt(),
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'] as String?,
        category: json['category'] as String?,
      ),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}