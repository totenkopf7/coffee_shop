import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('⚠️ Supabase credentials not found in .env file!');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Shop',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      onGenerateInitialRoutes: (String initialRoute) {
        final Uri currentUri = Uri.base;
        final String path = currentUri.path;
        final String query = currentUri.query;

        if (path.contains('menu')) {
          int? tableId;
          if (query.isNotEmpty) {
            final params = query.split('&');
            for (var param in params) {
              if (param.startsWith('table=')) {
                tableId = int.tryParse(param.split('=')[1]);
                break;
              }
            }
          }
          return [
            MaterialPageRoute(
              builder: (context) => MenuScreen(tableId: tableId),
            ),
          ];
        }

        return [
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        ];
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}
