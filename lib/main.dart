// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    print('✅ .env file loaded successfully');
  } catch (e) {
    print('⚠️ Could not load .env file: $e');
  }

  final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print('⚠️ Supabase credentials not found in .env!');
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    final isConfigured = supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

    return MaterialApp(
      title: 'Coffee Shop',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      // Remove home: and use initialRoute instead
      initialRoute: '/',
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

        // Return the splash screen or home screen based on configuration
        return [
          MaterialPageRoute(
            builder: (context) =>
                isConfigured ? const SplashScreen() : const ConfigErrorScreen(),
          ),
        ];
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) =>
              isConfigured ? const HomeScreen() : const ConfigErrorScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '☕',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              const Text(
                'Coffee Shop',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Management System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Lottie.asset(
                'assets/animations/loading.json',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '☕',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not load Supabase credentials.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please make sure the .env file is properly configured.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Required environment variables:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• SUPABASE_URL'),
                      const Text('• SUPABASE_ANON_KEY'),
                      const SizedBox(height: 8),
                      const Text(
                        'Add these to your .env file in the root of the project.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ConfigErrorScreen()),
                      );
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
