import '../core/constants.dart';

/// One "sitting" at a table — created when an employee opens the table,
/// closed when the customer pays and leaves.
class TableSession {
  final String id; // uuid
  final int tableId; // bigint
  final int tableNumber;
  final String status; // open | check_requested | closed
  final DateTime openedAt;
  final DateTime? checkRequestedAt;
  final DateTime? closedAt;

  const TableSession({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.status,
    required this.openedAt,
    this.checkRequestedAt,
    this.closedAt,
  });

  factory TableSession.fromMap(Map<String, dynamic> map) {
    return TableSession(
      id: map['id'] as String,
      tableId: (map['table_id'] as num).toInt(),
      tableNumber: (map['table_number'] as num).toInt(),
      status: (map['status'] as String?) ?? SessionStatus.open,
      openedAt: DateTime.parse(map['opened_at'] as String).toLocal(),
      checkRequestedAt: map['check_requested_at'] != null
          ? DateTime.parse(map['check_requested_at'] as String).toLocal()
          : null,
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String).toLocal()
          : null,
    );
  }

  bool get isOpen => status == SessionStatus.open;
  bool get isCheckRequested => status == SessionStatus.checkRequested;
  bool get isClosed => status == SessionStatus.closed;

  /// True while the customer is allowed to place new orders.
  bool get canOrder => status == SessionStatus.open;

  @override
  String toString() => 'Session($id, table #$tableNumber, $status)';
}