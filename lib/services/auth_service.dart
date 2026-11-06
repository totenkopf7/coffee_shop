// services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kLoggedIn = 'employee_logged_in';
  static const _kUsername = 'employee_username';
  static const _kDisplayName = 'employee_display_name';
  static const _kIsSuperAdmin = 'employee_is_super_admin';

  SupabaseClient get _client => Supabase.instance.client;

  bool _cached = false;
  bool _cachedIsSuperAdmin = false;
  String? _cachedUsername;
  String? _cachedDisplayName;
  String? get currentUsername => _cachedUsername;

  bool get isLoggedIn => _cached;
  bool get isSuperAdmin => _cachedIsSuperAdmin;
  String? get username => _cachedUsername;
  String? get displayName => _cachedDisplayName;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getBool(_kLoggedIn) ?? false;
    _cachedIsSuperAdmin = prefs.getBool(_kIsSuperAdmin) ?? false;
    _cachedUsername = prefs.getString(_kUsername);
    _cachedDisplayName = prefs.getString(_kDisplayName);
  }

  Future<bool> login(String username, String password) async {
    final u = username.trim();
    if (u.isEmpty) throw Exception('Enter your username.');
    if (password.isEmpty) throw Exception('Enter your password.');

    debugPrint('→ verify_employee(user="$u", role="admin")');

    final dynamic rows;
    try {
      rows = await _client.rpc(
        'verify_employee',
        params: {
          'p_username': u,
          'p_password': password,
          'p_required_role': 'admin',
        },
      );
    } catch (e) {
      debugPrint('❌ verify_employee RPC threw: $e');
      // Surface the real error to the UI
      throw Exception('Login failed: ${_short(e)}');
    }

    debugPrint('← verify_employee returned: $rows (type=${rows.runtimeType})');

    final list = rows is List ? rows : (rows == null ? const [] : [rows]);
    if (list.isEmpty) {
      throw Exception('Invalid username or password.');
    }

    final first = (list.first as Map).cast<String, dynamic>();
    _cached = true;
    _cachedIsSuperAdmin = false;
    _cachedUsername = (first['username'] as String?) ?? u;
    _cachedDisplayName = (first['display_name'] as String?) ?? _cachedUsername;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setBool(_kIsSuperAdmin, false);
    await prefs.setString(_kUsername, _cachedUsername!);
    await prefs.setString(_kDisplayName, _cachedDisplayName!);
    return true;
  }

  Future<bool> loginAsSuperAdmin(String username, String password) async {
    final u = username.trim();
    if (u.isEmpty) throw Exception('invalidCredentials'); // sentinel
    if (password.isEmpty) throw Exception('invalidCredentials');

    final dynamic rows;
    try {
      rows = await _client.rpc(
        'verify_super_admin',
        params: {'p_username': u, 'p_password': password},
      );
    } catch (e) {
      throw Exception('invalidCredentials');
    }

    final list = rows is List ? rows : (rows == null ? const [] : [rows]);
    if (list.isEmpty) {
      throw Exception('Invalid username or password.');
    }

    final first = (list.first as Map).cast<String, dynamic>();
    _cached = true;
    _cachedIsSuperAdmin = true;
    _cachedUsername = (first['username'] as String?) ?? u;
    _cachedDisplayName = (first['display_name'] as String?) ?? _cachedUsername;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setBool(_kIsSuperAdmin, true);
    await prefs.setString(_kUsername, _cachedUsername!);
    await prefs.setString(_kDisplayName, _cachedDisplayName!);
    return true;
  }

  Future<void> logout() async {
    _cached = false;
    _cachedIsSuperAdmin = false;
    _cachedUsername = null;
    _cachedDisplayName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kIsSuperAdmin);
    await prefs.remove(_kUsername);
    await prefs.remove(_kDisplayName);
  }

  String _short(Object e) {
    final s = e.toString();
    return s.length > 200 ? '${s.substring(0, 200)}…' : s;
  }
}
