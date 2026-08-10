import 'package:flutter/material.dart';

class CoffeeTable {
  final int id;
  final int tableNumber;
  final String status;
  final DateTime? createdAt;

  const CoffeeTable({
    required this.id,
    required this.tableNumber,
    this.status = 'available',
    this.createdAt,
  });

  factory CoffeeTable.fromMap(Map<String, dynamic> map) {
    return CoffeeTable(
      id: map['id'] as int,
      tableNumber: map['table_number'] as int,
      status: map['status'] as String? ?? 'available',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_number': tableNumber,
      'status': status,
    };
  }

  bool get isOccupied => status == 'occupied';
  bool get isAvailable => status == 'available';

  String get statusDisplay => isOccupied ? 'TAKEN' : 'AVAILABLE';
  Color get statusColor => isOccupied ? Colors.red : Colors.green;
  Color get statusBackgroundColor =>
      isOccupied ? Colors.red.shade100 : Colors.green.shade100;
  Color get cardBorderColor =>
      isOccupied ? Colors.red.shade300 : Colors.grey.shade300;
  Color get cardBackgroundColor =>
      isOccupied ? Colors.red.shade50 : Colors.white;
  Color get tableNumberColor =>
      isOccupied ? Colors.red.shade800 : Colors.brown.shade800;
}
