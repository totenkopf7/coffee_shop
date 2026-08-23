// widgets/table_card.dart
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
            color: table.cardBackgroundColor.withOpacity(0.9),
            border: Border.all(
              color: table.cardBorderColor,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Table icon from assets
              Image.asset(
                'assets/images/table.png',
                width: 40,
                height: 40,
                color: table.tableNumberColor,
              ),
              const SizedBox(height: 4),
              Text(
                '${table.tableNumber}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: table.tableNumberColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: table.statusBackgroundColor,
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
                        color: table.statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      table.statusDisplay,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: table.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
