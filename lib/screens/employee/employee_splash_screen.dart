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
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Timeout in case SharedPreferences is stuck on a slow device.
    try {
      await AuthService.instance.load().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignore — auth state defaults to logged out, which is safe.
    }
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
            // White-outlined fallback spinner is always visible, even if
            // Lottie fails to load. The Lottie animation sits on top.
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  Lottie.asset(
                    'assets/animations/loading.json',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
