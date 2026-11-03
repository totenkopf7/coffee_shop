import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class TableClosedScreen extends StatelessWidget {
  final int tableNumber;
  const TableClosedScreen({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☕', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              const Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Table $tableNumber has been closed. Have a great day!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}