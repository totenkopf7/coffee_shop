// main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'screens/customer/customer_entry_screen.dart';
import 'screens/employee/employee_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('🚨 FlutterError: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  String url = const String.fromEnvironment('SUPABASE_URL');
  String anon = const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isEmpty || anon.isEmpty) {
    try {
      await dotenv.load(fileName: '.env').timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('⚠️ Could not load .env file: $e');
    }
    if (url.isEmpty) url = dotenv.env['SUPABASE_URL'] ?? '';
    if (anon.isEmpty) anon = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  if (url.isEmpty || anon.isEmpty) {
    runApp(
      const _BootstrapApp(
        child: _ConfigErrorScreen(
          title: 'Missing configuration',
          message: 'SUPABASE_URL or SUPABASE_ANON_KEY was not found.\n\n'
              'On Vercel: add them under Environment Variables and build with\n'
              '  flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...\n\n'
              'Locally: put them in .env and ensure `.env` is listed under\n'
              '`flutter: assets:` in pubspec.yaml.',
        ),
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(url: url, anonKey: anon)
        .timeout(const Duration(seconds: 12));
  } catch (e) {
    debugPrint('⚠️ Supabase.initialize failed: $e');
    runApp(
      _BootstrapApp(
        child: _ConfigErrorScreen(
          title: 'Cannot reach Supabase',
          message: 'Supabase failed to initialize:\n$e\n\n'
              'Check SUPABASE_URL and SUPABASE_ANON_KEY, and that this device '
              'has internet access.',
        ),
      ),
    );
    return;
  }

  runApp(const CoffeeShopApp());
}

class _BootstrapApp extends StatelessWidget {
  final Widget child;
  const _BootstrapApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6F4E37)),
      ),
      home: child,
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  const _ConfigErrorScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('☕', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _ready = false;
  Widget _target = const SizedBox.shrink();
  int _attempts = 0;
  static const int _maxAttempts = 8;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResolve());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  String _rawUrl() => Uri.base.toString();

  bool _isCustomerUrl(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('/menu') ||
        lower.contains('table=') ||
        lower.contains('#/menu');
  }

  int? _parseTableFromUrl(String raw) {
    final uri = Uri.base;
    final qTable = uri.queryParameters['table'];
    if (qTable != null) {
      final n = int.tryParse(qTable);
      if (n != null && n > 0) return n;
    }

    final m = RegExp(r'table=(\d+)').firstMatch(raw);
    if (m != null) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null && n > 0) return n;
    }
    return null;
  }

  void _tryResolve() {
    if (!mounted || _ready) return;

    final raw = _rawUrl();
    final isCustomer = _isCustomerUrl(raw);

    debugPrint('🧭 Resolve attempt ${_attempts + 1}/$_maxAttempts: raw=$raw '
        'isCustomer=$isCustomer');

    if (isCustomer) {
      final table = _parseTableFromUrl(raw);
      debugPrint('🧭 Customer route, table=$table');
      setState(() {
        _target = CustomerEntryScreen(tableNumber: table);
        _ready = true;
      });
      return;
    }

    if (_attempts < _maxAttempts) {
      _attempts++;
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 120), () {
        if (!mounted || _ready) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryResolve());
      });
      return;
    }

    debugPrint('🧭 Employee route (no customer URL found after retries)');
    setState(() {
      _target = const EmployeeSplashScreen();
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('☕', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Waking up…',
                style: TextStyle(color: Color(0xFF6D5B50), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return _target;
  }
}
