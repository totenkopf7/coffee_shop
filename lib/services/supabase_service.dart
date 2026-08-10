import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';

/// Main service that handles all communication with Supabase
class SupabaseService {
  // The Supabase client instance
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // PRODUCT OPERATIONS
  // ============================================================

  /// Gets all available products from the database
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

  /// Gets a single product by its ID
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

  /// Gets all tables from the database
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

  /// Updates a table's status
  Future<void> updateTableStatus(int tableId, String status) async {
    try {
      await _client.from('tables').update({'status': status}).eq('id', tableId);
    } catch (e) {
      print('Error in updateTableStatus: $e');
      throw Exception('Failed to update table status: $e');
    }
  }

  // ============================================================
  // ORDER OPERATIONS
  // ============================================================

  /// Gets the active (open) order for a table
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

  /// Creates a new order for a table
  Future<Order> createOrder(int tableId) async {
    try {
      final response = await _client
          .from('orders')
          .insert({
            'table_id': tableId,
            'status': 'open',
            'total': 0.0,
          })
          .select()
          .single();

      await updateTableStatus(tableId, 'occupied');

      final map = response as Map<String, dynamic>;
      return Order.fromMap(map);
    } catch (e) {
      print('Error in createOrder: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  /// Gets all items for an order
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

  /// Adds an item to an order
  Future<OrderItem> addOrderItem(String orderId, int productId,
      {int quantity = 1}) async {
    try {
      // 1. Get the product details
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Product not found or unavailable');
      }

      // 2. Check if this product already exists in the order
      final existingItems = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItems != null) {
        // Update existing item: increase quantity
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

      // 3. Insert new order item
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

  /// Updates the total of an order
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

  /// Closes an order
  Future<Order> closeOrder(String orderId) async {
    try {
      // 1. Get the order to find its table
      final orderResponse =
          await _client.from('orders').select().eq('id', orderId).single();

      final orderMap = orderResponse as Map<String, dynamic>;
      final order = Order.fromMap(orderMap);

      // 2. Update the order status
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

      // 3. Update the table status to 'available'
      await updateTableStatus(order.tableId, 'available');

      final map = updatedOrder as Map<String, dynamic>;
      return Order.fromMap(map);
    } catch (e) {
      print('Error in closeOrder: $e');
      throw Exception('Failed to close order: $e');
    }
  }

  /// Gets a complete order with all its items
  Future<Map<String, dynamic>> getCompleteOrder(String orderId) async {
    try {
      // 1. Get the order
      final orderData =
          await _client.from('orders').select().eq('id', orderId).single();

      final orderMap = orderData as Map<String, dynamic>;
      final order = Order.fromMap(orderMap);

      // 2. Get the table details
      final tableData = await _client
          .from('tables')
          .select()
          .eq('id', order.tableId)
          .single();

      final tableMap = tableData as Map<String, dynamic>;
      final table = CoffeeTable.fromMap(tableMap);

      // 3. Get all order items with product details
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

  /// Get all orders with their table information
  /// Get all orders with their table information
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, tables(*)')
          .order('created_at', ascending: false);

      // Explicitly cast the response to List<Map<String, dynamic>>
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

  /// Get total number of orders
  Future<int> getTotalOrdersCount() async {
    try {
      final response = await _client.from('orders').select('id');

      return response.length;
    } catch (e) {
      print('Error in getTotalOrdersCount: $e');
      return 0;
    }
  }

  /// Get today's orders count
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

  /// Get total revenue from closed orders
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

  /// Get all orders with items for a specific table
  /// Get all orders with items for a specific table
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
