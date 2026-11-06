// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_localizations.dart';
import 'core/app_theme.dart';
import 'core/config.dart';
import 'core/kurdish_material_localizations.dart';
import 'core/locale_provider.dart';
import 'screens/customer/customer_entry_screen.dart';
import 'screens/employee/employee_splash_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await AuthService.instance.load();

  runApp(CoffeeShopApp(localeProvider: localeProviderInstance));
}

class CoffeeShopApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  const CoffeeShopApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeProvider,
      builder: (context, _) => MaterialApp(
        title: 'Coffee Shop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: localeProvider.locale,
        supportedLocales: const [
          Locale('en'),
          Locale('ku'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          KurdishMaterialLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final isKu = Localizations.localeOf(context).languageCode == 'en';
          return Directionality(
            textDirection: isKu ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final path = uri.path.toLowerCase();
    final fragment = uri.fragment.toLowerCase();
    final query = uri.queryParameters;

    int? tableNumber;
    final direct = query['table'];
    if (direct != null) tableNumber = int.tryParse(direct);

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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Missing Supabase URL or anon key in core/config.dart',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
