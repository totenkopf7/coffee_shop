/// A physical table in the shop.
///
/// `id` matches `tables.id` (bigint in Postgres).
/// `tableNumber` matches `tables.table_number` (int).
/// `isOpen` is the source of truth — a table is orderable only when open.
class CoffeeTable {
  final int id;
  final int tableNumber;
  final bool isOpen;

  const CoffeeTable({
    required this.id,
    required this.tableNumber,
    required this.isOpen,
  });

  factory CoffeeTable.fromMap(Map<String, dynamic> map) {
    return CoffeeTable(
      id: (map['id'] as num).toInt(),
      tableNumber: (map['table_number'] as num).toInt(),
      isOpen: (map['is_open'] as bool?) ?? false,
    );
  }

  CoffeeTable copyWith({bool? isOpen}) => CoffeeTable(
        id: id,
        tableNumber: tableNumber,
        isOpen: isOpen ?? this.isOpen,
      );

  @override
  String toString() => 'CoffeeTable(#$tableNumber, open=$isOpen)';
}