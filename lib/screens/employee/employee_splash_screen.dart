// screens/employee/employee_splash_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../services/auth_service.dart';
import '../super_admin/super_admin_reports_screen.dart';
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
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    try {
      await AuthService.instance.load();
    } catch (_) {}
    if (!mounted) return;

    Widget next;
    if (!AuthService.instance.isLoggedIn) {
      next = const EmployeeLoginScreen();
    } else if (AuthService.instance.isSuperAdmin) {
      next = const SuperAdminReportsScreen();
    } else {
      next = const TablesDashboard();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.t(context);
    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Brand logo ─────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/images/coffeeshop_logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  '☕',
                  style: TextStyle(fontSize: 76),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.staffConsole,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            if (kIsWeb)
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            else
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
