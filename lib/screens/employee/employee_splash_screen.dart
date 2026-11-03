// screens\employee\employee_splash_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import 'employee_login_screen.dart';
import 'tables_dashboard.dart';

class EmployeeSplashScreen extends StatefulWidget {
  const EmployeeSplashScreen({super.key});

  @override
  State<EmployeeSplashScreen> createState() => _EmployeeSplashScreenState();
}

class _EmployeeSplashScreenState extends State<EmployeeSplashScreen> {
  @override
  void initState() {
    super.initState();
    _afterSplash();
  }

  Future<void> _afterSplash() async {
    // Small delay for the branded splash animation.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Refresh state in case something changed (e.g. another tab logged out).
    await AuthService.instance.load();
    if (!mounted) return;

    final next = AuthService.instance.isLoggedIn
        ? const TablesDashboard()
        : const EmployeeLoginScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('☕', style: TextStyle(fontSize: 76)),
            const SizedBox(height: 12),
            const Text(
              'Coffee Shop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Staff Console',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            Lottie.asset(
              'assets/animations/loading.json',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
