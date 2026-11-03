import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  String _key(String sessionId) => 'cart_$sessionId';

  Future<List<CartItem>> load(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(sessionId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(String sessionId, List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key(sessionId), raw);
  }

  Future<void> clear(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(sessionId));
  }
}