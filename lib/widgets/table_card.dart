import 'package:flutter/material.dart';
import '../models/coffee_table.dart';

class TableCard extends StatelessWidget {
  final CoffeeTable table;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: table.isOccupied ? Colors.red[50] : Colors.white,
            border: Border.all(
              color: table.isOccupied ? Colors.red[300]! : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Table number
              Text(
                '${table.tableNumber}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: table.isOccupied ? Colors.red[800] : Colors.brown[800],
                ),
              ),
              const SizedBox(height: 8),

              // Status indicator - Changed to RED for occupied
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: table.isOccupied ? Colors.red[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: table.isOccupied ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      table.isOccupied ? 'TAKEN' : 'AVAILABLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: table.isOccupied
                            ? Colors.red[800]
                            : Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Icon(
                table.isOccupied ? Icons.person : Icons.person_outline,
                color: table.isOccupied ? Colors.red[300] : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
