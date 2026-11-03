import 'product.dart';

/// A single line item inside an order.
class OrderItem {
  final String id; // uuid
  final String orderId; // uuid
  final int productId; // int
  final int quantity;
  final double unitPrice; // snapshot at time of order
  final String nameSnapshot; // snapshot of product name at order time

  /// Optional joined product object (present when we join products(*)).
  final Product? product;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.nameSnapshot,
    this.product,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    Product? joined;
    if (map['products'] is Map<String, dynamic>) {
      joined = Product.fromMap(map['products'] as Map<String, dynamic>);
    }
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: (map['product_id'] as num).toInt(),
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      nameSnapshot: (map['name_snapshot'] as String?) ??
          joined?.name ??
          'Product ${map['product_id']}',
      product: joined,
    );
  }

  double get totalPrice => unitPrice * quantity;
  String get displayName => product?.name ?? nameSnapshot;
  String get formattedPrice => '\$${unitPrice.toStringAsFixed(2)}';
  String get formattedTotal => '\$${totalPrice.toStringAsFixed(2)}';

  @override
  String toString() => 'OrderItem($displayName x$quantity)';
}