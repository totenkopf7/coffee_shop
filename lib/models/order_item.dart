// models/order_item.dart
import 'product.dart';

class OrderItem {
  final String id;
  final String orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final String nameSnapshot;
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
    final raw = map['products'];
    if (raw is Map) {
      joined = Product.fromMap(Map<String, dynamic>.from(raw));
    }
    return OrderItem(
      id: map['id'] as String,
      orderId: (map['order_id'] as String?) ?? '',
      productId: (map['product_id'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
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
