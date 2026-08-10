import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // PRODUCT OPERATIONS
  // ============================================================

  Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('is_available', true)
          .order('name');

      final List<Product> products = [];
      for (var item in response) {
        final map = item as Map<String, dynamic>;
        products.add(Product.fromMap(map));
      }
      return products;
    } catch (e) {
      print('Error in getProducts: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', id)
          .eq('is_available', true)
          .maybeSingle();

      if (response == null) return null;

      final map = response as Map<String, dynamic>;
      return Product.fromMap(map);
    } catch (e) {
      print('Error in getProductById: $e');
      throw Exception('Failed to fetch product: $e');
    }
  }

  // ============================================================
  // TABLE OPERATIONS
  // ============================================================

  Future<List<CoffeeTable>> getTables() async {
    try {
      final response =
          await _client.from('tables').select().order('table_number');

      final List<CoffeeTable> tables = [];
      for (var item in response) {
        final map = item as Map<String, dynamic>;
        tables.add(CoffeeTable.fromMap(map));
      }
      return tables;
    } catch (e) {
      print('Error in getTables: $e');
      throw Exception('Failed to fetch tables: $e');
    }
  }

  Future<void> updateTableStatus(int tableId, String status) async {
    try {
      print('🔄 Updating table $tableId status to: $status');

      // Simple update without select first (more reliable)
      await _client.from('tables').update({'status': status}).eq('id', tableId);

      print('✅ Update command sent for table $tableId');

      // Verify the update worked
      final verify =
          await _client.from('tables').select().eq('id', tableId).single();

      print('📊 Verified table status: ${verify['status']}');

      if (verify['status'] != status) {
        throw Exception('Status update failed');
      }
    } catch (e) {
      print('❌ Error in updateTableStatus: $e');
      throw Exception('Failed to update table status: $e');
    }
  }

  // ============================================================
  // ORDER OPERATIONS
  // ============================================================

  Future<Order?> getActiveOrder(int tableId) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('table_id', tableId)
          .eq('status', 'open')
          .maybeSingle();

      if (response == null) return null;

      final map = response as Map<String, dynamic>;
      return Order.fromMap(map);
    } catch (e) {
      print('Error in getActiveOrder: $e');
      throw Exception('Failed to fetch active order: $e');
    }
  }

  /// SIMPLIFIED createOrder - directly updates table status
  Future<Order> createOrder(int tableId) async {
    try {
      print('🔄 Creating order for table: $tableId');

      // First, check if there's already an open order
      final existingOrder = await getActiveOrder(tableId);
      if (existingOrder != null) {
        print(
            '⚠️ Table $tableId already has an open order: ${existingOrder.id}');
        // Make sure table status is occupied
        await updateTableStatus(tableId, 'occupied');
        return existingOrder;
      }

      // Create the order
      final response = await _client
          .from('orders')
          .insert({
            'table_id': tableId,
            'status': 'open',
            'total': 0.0,
          })
          .select()
          .single();

      print('✅ Order created: ${response['id']}');

      // CRITICAL: Update the table status to 'occupied'
      // Using a direct update without select for reliability
      await _client
          .from('tables')
          .update({'status': 'occupied'}).eq('id', tableId);

      print('✅ Table $tableId status set to occupied');

      // Verify the table status was updated
      final verifyTable =
          await _client.from('tables').select().eq('id', tableId).single();

      print(
          '📊 Table ${verifyTable['table_number']} status after update: ${verifyTable['status']}');

      if (verifyTable['status'] != 'occupied') {
        print('⚠️ WARNING: Table status is still ${verifyTable['status']}');
        // Try one more time with a different approach
        await _client
            .from('tables')
            .update({'status': 'occupied'}).eq('id', tableId);
      }

      final map = response as Map<String, dynamic>;
      return Order.fromMap(map);
    } catch (e) {
      print('❌ Error in createOrder: $e');
      // Try to update table status anyway
      try {
        await _client
            .from('tables')
            .update({'status': 'occupied'}).eq('id', tableId);
        print('✅ Table status updated after error');
      } catch (e2) {
        print('❌ Failed to update table status even after error: $e2');
      }
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final response =
          await _client.from('order_items').select().eq('order_id', orderId);

      final List<OrderItem> items = [];
      for (var item in response) {
        final map = item as Map<String, dynamic>;
        items.add(OrderItem.fromMap(map));
      }
      return items;
    } catch (e) {
      print('Error in getOrderItems: $e');
      throw Exception('Failed to fetch order items: $e');
    }
  }

  Future<OrderItem> addOrderItem(String orderId, int productId,
      {int quantity = 1}) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Product not found or unavailable');
      }

      // Check if this product already exists in the order
      final existingItems = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItems != null) {
        final currentQuantity = existingItems['quantity'] as int;
        final newQuantity = currentQuantity + quantity;

        await _client
            .from('order_items')
            .update({'quantity': newQuantity}).eq('id', existingItems['id']);

        final updatedItem = await _client
            .from('order_items')
            .select()
            .eq('id', existingItems['id'])
            .single();

        await _updateOrderTotal(orderId);

        final map = updatedItem as Map<String, dynamic>;
        return OrderItem.fromMap(map);
      }

      final response = await _client
          .from('order_items')
          .insert({
            'order_id': orderId,
            'product_id': productId,
            'quantity': quantity,
            'unit_price': product.price,
          })
          .select()
          .single();

      await _updateOrderTotal(orderId);

      final map = response as Map<String, dynamic>;
      return OrderItem.fromMap(map);
    } catch (e) {
      print('Error in addOrderItem: $e');
      throw Exception('Failed to add order item: $e');
    }
  }

  Future<void> _updateOrderTotal(String orderId) async {
    try {
      final items = await _client
          .from('order_items')
          .select('quantity, unit_price')
          .eq('order_id', orderId);

      double total = 0.0;
      for (var item in items) {
        final map = item as Map<String, dynamic>;
        final quantity = map['quantity'] as int;
        final unitPrice = (map['unit_price'] as num).toDouble();
        total += quantity * unitPrice;
      }

      await _client.from('orders').update({'total': total}).eq('id', orderId);
    } catch (e) {
      print('Error in _updateOrderTotal: $e');
      throw Exception('Failed to update order total: $e');
    }
  }

  Future<Order> closeOrder(String orderId) async {
    try {
      final orderResponse =
          await _client.from('orders').select().eq('id', orderId).single();

      final orderMap = orderResponse as Map<String, dynamic>;
      final order = Order.fromMap(orderMap);

      final now = DateTime.now().toIso8601String();
      final updatedOrder = await _client
          .from('orders')
          .update({
            'status': 'closed',
            'closed_at': now,
          })
          .eq('id', orderId)
          .select()
          .single();

      // Update table status to available
      await updateTableStatus(order.tableId, 'available');

      final map = updatedOrder as Map<String, dynamic>;
      return Order.fromMap(map);
    } catch (e) {
      print('Error in closeOrder: $e');
      throw Exception('Failed to close order: $e');
    }
  }

  Future<Map<String, dynamic>> getCompleteOrder(String orderId) async {
    try {
      final orderData =
          await _client.from('orders').select().eq('id', orderId).single();

      final orderMap = orderData as Map<String, dynamic>;
      final order = Order.fromMap(orderMap);

      final tableData = await _client
          .from('tables')
          .select()
          .eq('id', order.tableId)
          .single();

      final tableMap = tableData as Map<String, dynamic>;
      final table = CoffeeTable.fromMap(tableMap);

      final itemsData =
          await _client.from('order_items').select().eq('order_id', orderId);

      final items = <OrderItem>[];
      for (var itemData in itemsData) {
        final map = itemData as Map<String, dynamic>;
        final item = OrderItem.fromMap(map);

        final product = await getProductById(item.productId);
        if (product != null) {
          items.add(OrderItem(
            id: item.id,
            orderId: item.orderId,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            createdAt: item.createdAt,
            product: product,
          ));
        } else {
          items.add(item);
        }
      }

      return {
        'order': order,
        'table': table,
        'items': items,
      };
    } catch (e) {
      print('Error in getCompleteOrder: $e');
      throw Exception('Failed to get complete order: $e');
    }
  }

  // ============================================================
  // ADDITIONAL METHODS FOR ORDERS AND REPORTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, tables(*)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = [];
      for (var item in response) {
        orders.add(item as Map<String, dynamic>);
      }
      return orders;
    } catch (e) {
      print('Error in getAllOrders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<int> getTotalOrdersCount() async {
    try {
      final response = await _client.from('orders').select('id');
      return response.length;
    } catch (e) {
      print('Error in getTotalOrdersCount: $e');
      return 0;
    }
  }

  Future<int> getTodayOrdersCount() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response =
          await _client.from('orders').select('id').gte('created_at', today);
      return response.length;
    } catch (e) {
      print('Error in getTodayOrdersCount: $e');
      return 0;
    }
  }

  Future<double> getTotalRevenue() async {
    try {
      final response =
          await _client.from('orders').select('total').eq('status', 'closed');

      double total = 0;
      for (var order in response) {
        total += (order['total'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Error in getTotalRevenue: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByTable(int tableId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, tables(*)')
          .eq('table_id', tableId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = [];
      for (var item in response) {
        orders.add(item as Map<String, dynamic>);
      }
      return orders;
    } catch (e) {
      print('Error in getOrdersByTable: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }
}
