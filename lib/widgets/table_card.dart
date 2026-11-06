// widgets/table_card.dart
import 'package:coffee_shop/core/config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/coffee_table.dart';

enum TableVisualState { closed, open, ordering, checkRequested }

class TableCard extends StatelessWidget {
  final CoffeeTable table;
  final TableVisualState state;
  final int orderCount;
  final double runningTotal;
  final bool isCheckRequested;
  final bool hasNewOrder;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.state,
    required this.orderCount,
    required this.runningTotal,
    required this.isCheckRequested,
    required this.hasNewOrder,
    required this.onTap,
  });

  Color get _accent {
    switch (state) {
      case TableVisualState.closed:
        return AppColors.latte;
      case TableVisualState.open:
        return AppColors.success;
      case TableVisualState.ordering:
        return AppColors.caramel;
      case TableVisualState.checkRequested:
        return AppColors.danger;
    }
  }

  Color get _bg {
    switch (state) {
      case TableVisualState.closed:
        return AppColors.cream;
      case TableVisualState.open:
        return AppColors.successLight.withOpacity(0.35);
      case TableVisualState.ordering:
        return AppColors.warningLight.withOpacity(0.5);
      case TableVisualState.checkRequested:
        return AppColors.dangerLight.withOpacity(0.5);
    }
  }

  String get _label {
    switch (state) {
      case TableVisualState.closed:
        return 'CLOSED';
      case TableVisualState.open:
        return 'OPEN';
      case TableVisualState.ordering:
        return 'ORDERING';
      case TableVisualState.checkRequested:
        return 'CHECK';
    }
  }

  IconData get _icon {
    switch (state) {
      case TableVisualState.closed:
        return Icons.lock_outline;
      case TableVisualState.open:
        return Icons.qr_code_2;
      case TableVisualState.ordering:
        return Icons.receipt_long;
      case TableVisualState.checkRequested:
        return Icons.notifications_active;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _accent, width: 1.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(_icon, size: 18, color: _accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _label,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${table.tableNumber}',
                          style: TextStyle(
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TABLE',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: _accent.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (orderCount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$orderCount',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          AppConfig.money(runningTotal),
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Center(
                      child: Text(
                        state == TableVisualState.closed
                            ? 'Tap to open'
                            : 'Waiting...',
                        style: TextStyle(
                          color: _accent.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (hasNewOrder)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
