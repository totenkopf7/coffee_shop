import 'product.dart';

class OrderItem {
  final String id;
  final String orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final DateTime? createdAt;
  Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.quantity = 1,
    required this.unitPrice,
    this.createdAt,
    this.product,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: (map['unit_price'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  double get totalPrice => unitPrice * quantity;
  String get formattedPrice => '\$${unitPrice.toStringAsFixed(2)}';
  String get formattedTotal => '\$${totalPrice.toStringAsFixed(2)}';
}
