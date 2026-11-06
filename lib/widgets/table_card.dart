// lib/widgets/table_card.dart
import 'dart:math' as math;

import 'package:coffee_shop/core/config.dart';
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

  bool get _isTableOpen => state != TableVisualState.closed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final base = math.min(w, h);

        // ── Sizes scale from the smaller cell dimension ───────────
        // LAMP is the hero element: ~44% of base, clamped 56–120 px.
        final pad = (base * 0.06).clamp(4.0, 12.0);
        final lampSize = (base * 0.44).clamp(56.0, 120.0);

        // Table number stays prominent below the lamp.
        final numberSize = (base * 0.24).clamp(20.0, 40.0);
        final tableLabelSize = (base * 0.06).clamp(7.0, 10.0);

        // Top and bottom rows scale but stay small so lamp has room.
        final labelSize = (base * 0.085).clamp(8.0, 12.0);
        final labelIcon = (base * 0.14).clamp(12.0, 18.0);
        final footTextSize = (base * 0.09).clamp(8.0, 12.0);
        final hintSize = (base * 0.09).clamp(8.0, 11.0);

        return Material(
          color: _bg,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _accent, width: 1.6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top row: state icon + label (compact) ───
                      Row(
                        children: [
                          Icon(_icon, size: labelIcon, color: _accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _label,
                              style: TextStyle(
                                color: _accent,
                                fontSize: labelSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // ── Center: BIG lamp + table number below ───
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                _isTableOpen
                                    ? 'assets/images/lamp_on.png'
                                    : 'assets/images/lamp_off.png',
                                width: lampSize,
                                height: lampSize,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                              ),
                              SizedBox(height: lampSize * 0.04),
                              Text(
                                '${table.tableNumber}',
                                style: TextStyle(
                                  fontSize: numberSize,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'TABLE',
                                style: TextStyle(
                                  fontSize: tableLabelSize,
                                  letterSpacing: 1.2,
                                  color: _accent.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom row: items + price OR hint ──────
                      if (orderCount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: (base * 0.04).clamp(3.0, 6.0),
                                vertical: (base * 0.015).clamp(1.0, 3.0),
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$orderCount',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: footTextSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  AppConfig.money(runningTotal),
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: footTextSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                              fontSize: hintSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Top-right: NEW badge (small, over the card) ────
                if (hasNewOrder)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
      },
    );
  }
}
