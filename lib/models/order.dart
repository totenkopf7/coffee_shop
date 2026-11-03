import '../core/constants.dart';

/// A single "round" of ordering inside a session.
/// One session can have many orders (round 1, round 2, ...).
class Order {
  final String id; // uuid
  final int tableId; // bigint
  final String? sessionId; // uuid — may be null for legacy rows
  final int roundNumber;
  final String status; // open | placed | preparing | served | check_requested | closed
  final double total;
  final DateTime createdAt;
  final DateTime? closedAt;

  const Order({
    required this.id,
    required this.tableId,
    required this.sessionId,
    required this.roundNumber,
    required this.status,
    required this.total,
    required this.createdAt,
    this.closedAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      tableId: (map['table_id'] as num).toInt(),
      sessionId: map['session_id'] as String?,
      roundNumber: (map['round_number'] as num?)?.toInt() ?? 1,
      status: (map['status'] as String?) ?? OrderStatus.placed,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String).toLocal()
          : null,
    );
  }

  bool get isClosed => status == OrderStatus.closed;
  bool get isOpen =>
      status == OrderStatus.open || status == OrderStatus.placed;

  String get statusDisplay {
    switch (status) {
      case OrderStatus.open:
        return 'OPEN';
      case OrderStatus.placed:
        return 'PLACED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.served:
        return 'SERVED';
      case OrderStatus.checkRequested:
        return 'CHECK REQUESTED';
      case OrderStatus.closed:
        return 'CLOSED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  String toString() => 'Order($id, table=$tableId, round=$roundNumber, $status)';
}