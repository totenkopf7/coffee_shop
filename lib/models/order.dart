import 'order_item.dart';

class Order {
  final String id;
  final int tableId;
  final String status;
  final double total;
  final DateTime? createdAt;
  final DateTime? closedAt;
  List<OrderItem> items;

  Order({
    required this.id,
    required this.tableId,
    this.status = 'open',
    this.total = 0.0,
    this.createdAt,
    this.closedAt,
    this.items = const [],
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      tableId: map['table_id'] as int,
      status: map['status'] as String? ?? 'open',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_id': tableId,
      'status': status,
      'total': total,
      'closed_at': closedAt?.toIso8601String(),
    };
  }

  double calculateTotal() {
    return items.fold(
        0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  String get statusDisplay => status.toUpperCase();
}
