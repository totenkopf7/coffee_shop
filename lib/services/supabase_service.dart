// services/supabase_service.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_with_items.dart';
import '../models/product.dart';
import '../models/table_session.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  int _nextChannelId() => DateTime.now().microsecondsSinceEpoch;

  // ── TABLES ──────────────────────────────────────────────────────────
  Future<List<CoffeeTable>> getTables() async {
    final rows = await _client
        .from('tables')
        .select('id, table_number, is_open')
        .order('table_number', ascending: true);
    return rows.map<CoffeeTable>((r) => CoffeeTable.fromMap(r)).toList();
  }

  Future<CoffeeTable?> getTableByNumber(int tableNumber) async {
    if (tableNumber <= 0 || tableNumber > 100000) return null;
    final row = await _client
        .from('tables')
        .select('id, table_number, is_open')
        .eq('table_number', tableNumber)
        .maybeSingle();
    if (row == null) return null;
    return CoffeeTable.fromMap(row);
  }

  Future<CoffeeTable?> getTableById(int id) async {
    if (id <= 0) return null;
    final row = await _client
        .from('tables')
        .select('id, table_number, is_open')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return CoffeeTable.fromMap(row);
  }

  Stream<List<CoffeeTable>> watchTables() {
    late StreamController<List<CoffeeTable>> controller;
    RealtimeChannel? channel;
    Future<void> emit() async {
      try {
        final rows = await getTables();
        if (!controller.isClosed) controller.add(rows);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<CoffeeTable>>(
      onListen: () async {
        channel = _client
            .channel('public:tables:${_nextChannelId()}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'tables',
              callback: (_) => emit(),
            )
            .subscribe();
        await emit();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        channel = null;
        await controller.close();
      },
    );
    return controller.stream;
  }

  // ── SESSIONS ────────────────────────────────────────────────────────
  Future<TableSession?> getActiveSessionForTable(int tableNumber) async {
    if (tableNumber <= 0) return null;
    final row = await _client
        .from('table_sessions')
        .select()
        .eq('table_number', tableNumber)
        .neq('status', SessionStatus.closed)
        .order('opened_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return TableSession.fromMap(row);
  }

  Future<TableSession?> getSessionById(String sessionId) async {
    if (sessionId.trim().isEmpty) return null;
    final row = await _client
        .from('table_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) return null;
    return TableSession.fromMap(row);
  }

  Future<List<TableSession>> getAllSessions() async {
    final rows = await _client
        .from('table_sessions')
        .select()
        .order('opened_at', ascending: false);
    return rows.map<TableSession>((r) => TableSession.fromMap(r)).toList();
  }

  Stream<List<TableSession>> watchAllSessions() {
    late StreamController<List<TableSession>> controller;
    RealtimeChannel? channel;
    Future<void> emit() async {
      try {
        final rows = await getAllSessions();
        if (!controller.isClosed) controller.add(rows);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<TableSession>>(
      onListen: () async {
        channel = _client
            .channel('public:table_sessions:${_nextChannelId()}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'table_sessions',
              callback: (_) => emit(),
            )
            .subscribe();
        await emit();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        channel = null;
        await controller.close();
      },
    );
    return controller.stream;
  }

  Stream<List<TableSession>> watchActiveSessions() =>
      watchAllSessions().map((s) => s.where((x) => !x.isClosed).toList());

  Stream<TableSession?> watchSession(String sessionId) {
    if (sessionId.trim().isEmpty) return Stream.value(null);
    late StreamController<TableSession?> controller;
    RealtimeChannel? channel;
    Future<void> emit() async {
      try {
        final s = await getSessionById(sessionId);
        if (!controller.isClosed) controller.add(s);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<TableSession?>(
      onListen: () async {
        channel = _client
            .channel('public:table_session:$sessionId:${_nextChannelId()}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'table_sessions',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: sessionId,
              ),
              callback: (_) => emit(),
            )
            .subscribe();
        await emit();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        channel = null;
        await controller.close();
      },
    );
    return controller.stream;
  }

  Future<TableSession> openTable(int tableNumber) async {
    final table = await getTableByNumber(tableNumber);
    if (table == null) throw Exception('Table $tableNumber does not exist');

    final existing = await getActiveSessionForTable(tableNumber);
    if (existing != null) {
      if (!table.isOpen) {
        await _client.from('tables').update({
          'is_open': true,
          'status': AppConstants.tableStatusOccupied,
        }).eq('id', table.id);
      }
      return existing;
    }

    final inserted = await _client
        .from('table_sessions')
        .insert({
          'table_id': table.id,
          'table_number': table.tableNumber,
          'status': SessionStatus.open,
        })
        .select()
        .single();

    await _client.from('tables').update({
      'is_open': true,
      'status': AppConstants.tableStatusOccupied,
    }).eq('id', table.id);

    return TableSession.fromMap(inserted);
  }

  Future<void> requestCheck(String sessionId) async {
    if (sessionId.trim().isEmpty) throw Exception('Invalid session id');
    await _client.rpc('request_check', params: {'p_session_id': sessionId});
  }

  Future<void> closeTable(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) throw Exception('Session not found');
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('orders')
        .update({'status': OrderStatus.closed, 'closed_at': nowUtc})
        .eq('session_id', sessionId)
        .neq('status', OrderStatus.closed);

    await _client.from('table_sessions').update({
      'status': SessionStatus.closed,
      'closed_at': nowUtc,
    }).eq('id', sessionId);

    await _client.from('tables').update({
      'is_open': false,
      'status': AppConstants.tableStatusAvailable,
    }).eq('id', session.tableId);
  }

  // ── PRODUCTS ────────────────────────────────────────────────────────
  Future<List<Product>> getAvailableProducts() async {
    final rows = await _client
        .from('products')
        .select()
        .eq('is_available', true)
        .order('category', ascending: true)
        .order('name', ascending: true);
    return rows.map<Product>((r) => Product.fromMap(r)).toList();
  }

  Future<List<Product>> getAllProducts() async {
    final rows =
        await _client.from('products').select().order('name', ascending: true);
    return rows.map<Product>((r) => Product.fromMap(r)).toList();
  }

  Future<Product?> getProductById(int id) async {
    if (id <= 0) return null;
    final row =
        await _client.from('products').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Product.fromMap(row);
  }

  Future<void> addProduct(Product product) async {
    await _client.from('products').insert(product.toInsertMap());
  }

  Future<void> updateProduct(Product product) async {
    if (product.id <= 0) throw Exception('Invalid product id');
    await _client
        .from('products')
        .update(product.toInsertMap())
        .eq('id', product.id);
  }

  Future<void> setProductAvailability(int id, bool available) async {
    if (id <= 0) throw Exception('Invalid product id');
    await _client
        .from('products')
        .update({'is_available': available}).eq('id', id);
  }

  Future<bool> productHasOrders(int id) async {
    if (id <= 0) return false;
    final rows = await _client
        .from('order_items')
        .select('id')
        .eq('product_id', id)
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<void> deleteProduct(int id) async {
    if (id <= 0) throw Exception('Invalid product id');
    if (await productHasOrders(id)) {
      throw Exception(
          'This product appears in existing orders. Hide it instead of deleting.');
    }
    await _client.from('products').delete().eq('id', id);
  }

  // ── ORDERS ──────────────────────────────────────────────────────────
  Future<List<OrderWithItems>> getOrdersForSession(String sessionId) async {
    if (sessionId.trim().isEmpty) return const [];
    final orderRows = await _client
        .from('orders')
        .select()
        .eq('session_id', sessionId)
        .order('round_number', ascending: true);

    final seen = <String>{};
    final uniqueRows = <Map<String, dynamic>>[];
    for (final row in orderRows) {
      final id = row['id'] as String;
      if (seen.add(id)) uniqueRows.add(row);
    }

    final result = <OrderWithItems>[];
    for (final row in uniqueRows) {
      final order = Order.fromMap(row);
      final items = await _getItemsForOrder(order.id);
      result.add(OrderWithItems(order: order, items: items));
    }
    result.sort((a, b) => a.order.roundNumber.compareTo(b.order.roundNumber));
    return result;
  }

  Stream<List<OrderWithItems>> watchOrdersForSession(String sessionId) {
    if (sessionId.trim().isEmpty) return Stream.value(const []);
    late StreamController<List<OrderWithItems>> controller;
    RealtimeChannel? channel;
    Future<void> emit() async {
      try {
        final list = await getOrdersForSession(sessionId);
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<OrderWithItems>>(
      onListen: () async {
        channel = _client
            .channel('public:orders:session:$sessionId:${_nextChannelId()}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'session_id',
                value: sessionId,
              ),
              callback: (_) => emit(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'order_items',
              callback: (_) => emit(),
            )
            .subscribe();
        await emit();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        channel = null;
        await controller.close();
      },
    );
    return controller.stream;
  }

  Future<List<Order>> getAllOrders() async {
    final rows = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false);
    return rows.map<Order>((r) => Order.fromMap(r)).toList();
  }

  Stream<List<Order>> watchAllOrders() {
    late StreamController<List<Order>> controller;
    RealtimeChannel? channel;
    Future<void> emit() async {
      try {
        final list = await getAllOrders();
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<Order>>(
      onListen: () async {
        channel = _client
            .channel('public:orders:all:${_nextChannelId()}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              callback: (_) => emit(),
            )
            .subscribe();
        await emit();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        channel = null;
        await controller.close();
      },
    );
    return controller.stream;
  }

  Future<List<OrderItem>> _getItemsForOrder(String orderId) async {
    if (orderId.trim().isEmpty) return const [];
    // Join products so we can display the product name (there is no
    // name_snapshot column in this schema).
    final rows = await _client
        .from('order_items')
        .select('*, products(*)')
        .eq('order_id', orderId);

    final seen = <String>{};
    final items = <OrderItem>[];
    for (final row in rows) {
      final id = row['id'] as String;
      if (!seen.add(id)) continue;
      items.add(OrderItem.fromMap(row));
    }
    return items;
  }

  Future<List<OrderItem>> getOrderItems(String orderId) =>
      _getItemsForOrder(orderId);

  Future<Order> placeOrder({
    required String sessionId,
    required int tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (sessionId.trim().isEmpty) throw Exception('Invalid session');
    if (tableId <= 0) throw Exception('Invalid table');
    if (items.isEmpty) throw Exception('Cannot place an empty order');

    for (final i in items) {
      final pid = i['productId'];
      final qty = i['quantity'];
      final price = i['unitPrice'];
      if (pid is! int || pid <= 0) throw Exception('Invalid product id');
      if (qty is! int || qty <= 0) throw Exception('Invalid quantity');
      if (price is! num || price < 0) throw Exception('Invalid price');
    }

    final existing = await _client
        .from('orders')
        .select('round_number')
        .eq('session_id', sessionId)
        .order('round_number', ascending: false)
        .limit(1);

    final nextRound = existing.isEmpty
        ? 1
        : ((existing.first['round_number'] as num).toInt() + 1);

    double total = 0;
    for (final i in items) {
      total += (i['quantity'] as int) * (i['unitPrice'] as num).toDouble();
    }

    final orderRow = await _client
        .from('orders')
        .insert({
          'table_id': tableId,
          'session_id': sessionId,
          'round_number': nextRound,
          'status': OrderStatus.placed,
          'total': total,
        })
        .select()
        .single();

    final orderId = orderRow['id'] as String;

    // NOTE: schema has no `name_snapshot` column — do NOT write it.
    final itemRows = items
        .map((i) => {
              'order_id': orderId,
              'product_id': i['productId'] as int,
              'quantity': i['quantity'] as int,
              'unit_price': (i['unitPrice'] as num).toDouble(),
            })
        .toList();

    await _client.from('order_items').insert(itemRows);

    return Order.fromMap(orderRow);
  }

  Future<Order> addStaffOrder({
    required String sessionId,
    required int tableId,
    required List<Map<String, dynamic>> items,
  }) =>
      placeOrder(sessionId: sessionId, tableId: tableId, items: items);

  // ── IMAGE UPLOAD (web-safe — no dart:io) ───────────────────────────
  Future<String?> uploadProductImage({
    required XFile file,
    required String productName,
  }) async {
    try {
      final safeName = productName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'png';
      final fileName = '${safeName.isEmpty ? 'product' : safeName}_'
          '${DateTime.now().millisecondsSinceEpoch}.$ext';

      final Uint8List bytes = await file.readAsBytes();

      await _client.storage.from('product-images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );

      return _client.storage.from('product-images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('uploadProductImage error: $e');
      return null;
    }
  }

  // ── REPORTS ────────────────────────────────────────────────────────
  Future<List<OrderWithItems>> getOrdersInRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (from.isAfter(to)) return const [];
    final rows = await _client
        .from('orders')
        .select()
        .gte('created_at', from.toUtc().toIso8601String())
        .lte('created_at', to.toUtc().toIso8601String())
        .order('created_at', ascending: false);

    final result = <OrderWithItems>[];
    for (final row in rows) {
      final order = Order.fromMap(row);
      final items = await _getItemsForOrder(order.id);
      result.add(OrderWithItems(order: order, items: items));
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllOrdersRaw() async {
    final rows = await _client
        .from('orders')
        .select('*, tables(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
