// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'screens/customer/customer_entry_screen.dart';
import 'screens/employee/employee_splash_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env defensively. If it fails (mobile browsers can occasionally
  // fail to serve the asset hash on first paint), we continue and show the
  // configuration error only if the values are actually missing.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e');
  }

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anon = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || anon.isEmpty) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(url: url, anonKey: anon);

  // Load persisted employee login state once. This does NOT gate the
  // customer path — it only affects what the splash shows the employee.
  await AuthService.instance.load();

  runApp(const CoffeeShopApp());
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _RootRouter(),
    );
  }
}

/// Decides at startup whether we are in employee mode or customer mode.
///
/// Customer mode is triggered when the app is opened with a URL like:
///   <web-url>/#/menu?table=2
///   <web-url>/menu?table=2
///   <web-url>/?table=2
///
/// On mobile, customers reach the Scan QR screen from the customer entry
/// screen. On web, the query string drives routing directly.
///
/// The customer path is NEVER gated by the employee login.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;

    // Mobile browsers sometimes append a trailing slash or keep the hash
    // inside `fragment` only. Normalize both before inspecting.
    final path = uri.path.toLowerCase();
    final fragment = uri.fragment.toLowerCase();
    final query = uri.queryParameters;

    // Table number can live in ?table=N, or inside #/menu?table=N.
    int? tableNumber;

    final direct = query['table'];
    if (direct != null) {
      tableNumber = int.tryParse(direct);
    }

    if (tableNumber == null && fragment.contains('?')) {
      final fragQuery = fragment.split('?').last;
      for (final pair in fragQuery.split('&')) {
        final kv = pair.split('=');
        if (kv.length == 2 && kv[0] == 'table') {
          tableNumber = int.tryParse(kv[1]);
          break;
        }
      }
    }

    final isCustomerRoute = tableNumber != null ||
        path.contains('/menu') ||
        fragment.contains('/menu') ||
        query.containsKey('table');

    if (isCustomerRoute) {
      return CustomerEntryScreen(tableNumber: tableNumber);
    }

    // Employee path: splash → (login if needed) → dashboard.
    return const EmployeeSplashScreen();
  }
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('☕', style: TextStyle(fontSize: 64)),
                SizedBox(height: 20),
                Text(
                  'Configuration Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'If you are on a phone, make sure the .env file is bundled '
                  'in the web build and that the browser is not blocking '
                  'local storage / third-party cookies.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
