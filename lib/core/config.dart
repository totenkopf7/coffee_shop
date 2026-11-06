// lib/core/config.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  // Supabase project credentials
  static const String supabaseUrl = 'https://lglbjhipdayiuvnrtakd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbGJqaGlwZGF5aXV2bnJ0YWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzNTI4NDQsImV4cCI6MjEwMTkyODg0NH0.OYtncQsCjs8_5b0DVW9qBZVKpGLImpN7fJiWqxPV_nA';

  /// Base URL used inside customer QR codes.
  ///
  /// Resolution order:
  ///   1. `CUSTOMER_WEB_BASE_URL` dart-define (for explicit override —
  ///      use `flutter build web --dart-define=CUSTOMER_WEB_BASE_URL=...`)
  ///   2. Current web page origin (localhost, Vercel, Netlify, custom domain)
  ///   3. Fallback (used on mobile builds where Uri.base isn't meaningful)
  static String get customerWebBaseUrl {
    const override = String.fromEnvironment('CUSTOMER_WEB_BASE_URL');
    if (override.isNotEmpty) return _strip(override);

    if (kIsWeb) {
      final origin = Uri.base.origin; // e.g. "https://myapp.vercel.app"
      if (origin.isNotEmpty && origin != 'null') {
        return _strip(origin);
      }
    }

    // Fallback for native mobile builds (customer scans QR on desktop web
    // anyway, so this rarely matters).
    return 'http://localhost:5004';
  }

  static String _strip(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  static const int tableCount = 8;
  static const String currency = '\$';
}
