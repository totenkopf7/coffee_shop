// lib/core/config.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class AppConfig {
  AppConfig._();

  static const String supabaseUrl = 'https://lglbjhipdayiuvnrtakd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbGJqaGlwZGF5aXV2bnJ0YWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzNTI4NDQsImV4cCI6MjEwMTkyODg0NH0.OYtncQsCjs8_5b0DVW9qBZVKpGLImpN7fJiWqxPV_nA';

  static String get customerWebBaseUrl {
    const override = String.fromEnvironment('CUSTOMER_WEB_BASE_URL');
    if (override.isNotEmpty) return _strip(override);

    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        return _strip(origin);
      }
    }
    return 'http://localhost:5004';
  }

  static String _strip(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  static const int tableCount = 8;
  static const String currency = 'IQD';

  static final NumberFormat _money = NumberFormat('#,##0', 'en');

  /// Plain money string:  "5,000 IQD"
  /// Rendering order is fixed in the widgets by wrapping in LTR
  /// (see [MoneyText]).
  static String money(num value) => '${_money.format(value)} $currency';

  /// Same as [money] — kept for backward compatibility with PDF code.
  static String moneyPlain(num value) => money(value);
}
