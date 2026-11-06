import 'package:coffee_shop/core/config.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Confirms opening a table. Returns true if staff confirmed.
Future<bool> showOpenTableDialog(BuildContext context, int tableNumber) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: Row(
        children: [
          const Icon(Icons.lock_open, color: AppColors.success),
          const SizedBox(width: 8),
          Text('Open Table $tableNumber?'),
        ],
      ),
      content: const Text(
        'This activates the QR code on the table so the customer can '
        'scan it, browse the menu, and place orders.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Open Table'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Confirms closing a table + shows running total. Returns true if staff confirmed.
Future<bool> showCloseTableDialog(
  BuildContext context,
  int tableNumber,
  double total,
  int roundCount,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: Row(
        children: const [
          Icon(Icons.lock_outline, color: AppColors.danger),
          SizedBox(width: 8),
          Text('Close Table?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Table $tableNumber will be freed and the QR disabled.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rounds: $roundCount',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Total: ${AppConfig.money(total)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Close Table'),
        ),
      ],
    ),
  );
  return result ?? false;
}
