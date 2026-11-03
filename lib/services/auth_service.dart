// services\auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal employee auth — username + password verified via a
/// security-definer RPC in Postgres. No Supabase Auth. The customer
/// path never touches this class.
///
/// State is persisted in SharedPreferences so the employee stays logged
/// in across hot restarts and page reloads.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kLoggedIn = 'employee_logged_in';
  static const _kUsername = 'employee_username';
  static const _kDisplayName = 'employee_display_name';

  SupabaseClient get _client => Supabase.instance.client;

  bool _cached = false;
  String? _cachedUsername;
  String? _cachedDisplayName;

  bool get isLoggedIn => _cached;
  String? get username => _cachedUsername;
  String? get displayName => _cachedDisplayName;

  /// Load persisted state. Call once at app startup on the employee branch.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getBool(_kLoggedIn) ?? false;
    _cachedUsername = prefs.getString(_kUsername);
    _cachedDisplayName = prefs.getString(_kDisplayName);
  }

  /// Verify credentials against the `verify_employee` RPC.
  /// Returns `true` on success, throws on failure with a user-friendly
  /// message in the exception.
  Future<bool> login(String username, String password) async {
    final u = username.trim();
    if (u.isEmpty) throw Exception('Enter your username.');
    if (password.isEmpty) throw Exception('Enter your password.');

    final rows = await _client.rpc(
      'verify_employee',
      params: {'p_username': u, 'p_password': password},
    );

    // The RPC returns a set of rows. If empty → bad credentials.
    final list = (rows is List) ? rows : const [];
    if (list.isEmpty) {
      throw Exception('Invalid username or password.');
    }

    final first = list.first as Map<String, dynamic>;
    _cached = true;
    _cachedUsername = (first['username'] as String?) ?? u;
    _cachedDisplayName =
        (first['display_name'] as String?) ?? _cachedUsername;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kUsername, _cachedUsername!);
    await prefs.setString(_kDisplayName, _cachedDisplayName!);

    debugPrint('✅ Employee login OK: $_cachedUsername');
    return true;
  }

  Future<void> logout() async {
    _cached = false;
    _cachedUsername = null;
    _cachedDisplayName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kUsername);
    await prefs.remove(_kDisplayName);
  }
}