// services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ============================================================
  // IMAGE UPLOAD METHODS
  // ============================================================

  Future<String?> uploadProductImage({
    required String filePath,
    required String productName,
  }) async {
    try {
      final String extension = filePath.split('.').last;
      final String fileName =
          '${productName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      if (kIsWeb) {
        // For web, download the image and upload its bytes.
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image: ${response.statusCode}');
        }

        await _client.storage.from('product-images').uploadBinary(
              fileName,
              response.bodyBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      } else {
        // For mobile/desktop: read file and upload bytes
        final file = File(filePath);
        final bytes = await file.readAsBytes();

        await _client.storage.from('product-images').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      }

      final String publicUrl =
          _client.storage.from('product-images').getPublicUrl(fileName);
      print('✅ Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _client.storage.from('product-images').remove([fileName]);
      print('✅ Image deleted successfully');
    } catch (e) {
      print('❌ Error deleting image: $e');
    }
  }

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

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _client.from('products').select().order('name');

      final List<Product> products = [];
      for (var item in response) {
        final map = item as Map<String, dynamic>;
        products.add(Product.fromMap(map));
      }
      return products;
    } catch (e) {
      print('Error in getAllProducts: $e');
      throw Exception('Failed to fetch all products: $e');
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
  // PRODUCT MANAGEMENT OPERATIONS
  // ============================================================

  Future<void> addProduct({
    required String name,
    String? description,
    required double price,
    String? category,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    try {
      await _client.from('products').insert({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'is_available': isAvailable,
      });
      print('✅ Product added successfully: $name');
    } catch (e) {
      print('Error in addProduct: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    String? description,
    required double price,
    String? category,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    try {
      await _client.from('products').update({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'is_available': isAvailable,
      }).eq('id', id);
      print('✅ Product updated successfully: $name');
    } catch (e) {
      print('Error in updateProduct: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> updateProductAvailability(int id, bool isAvailable) async {
    try {
      await _client.from('products').update({
        'is_available': isAvailable,
      }).eq('id', id);
      print('✅ Product availability updated: $id -> $isAvailable');
    } catch (e) {
      print('Error in updateProductAvailability: $e');
      throw Exception('Failed to update product availability: $e');
    }
  }

  Future<bool> productHasOrders(int productId) async {
    try {
      final response = await _client
          .from('order_items')
          .select('id')
          .eq('product_id', productId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking product orders: $e');
      return true;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final hasOrders = await productHasOrders(id);

      if (hasOrders) {
        throw Exception(
            'Cannot delete product with existing orders. Hide it instead.');
      }

      final product = await _client
          .from('products')
          .select('image_url')
          .eq('id', id)
          .maybeSingle();

      await _client.from('products').delete().eq('id', id);

      if (product != null && product['image_url'] != null) {
        await deleteProductImage(product['image_url']);
      }

      print('✅ Product deleted successfully: $id');
    } catch (e) {
      print('Error in deleteProduct: $e');
      throw Exception('Failed to delete product: $e');
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

  Future<CoffeeTable?> getTableById(int id) async {
    try {
      final response =
          await _client.from('tables').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      final map = response as Map<String, dynamic>;
      return CoffeeTable.fromMap(map);
    } catch (e) {
      print('Error in getTableById: $e');
      throw Exception('Failed to fetch table: $e');
    }
  }

  Future<void> updateTableStatus(int tableId, String status) async {
    try {
      print('🔄 Updating table $tableId status to: $status');
      await _client.from('tables').update({'status': status}).eq('id', tableId);
      print('✅ Update command sent for table $tableId');

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

  Future<Order> createOrder(int tableId) async {
    try {
      print('🔄 Creating order for table: $tableId');

      final existingOrder = await getActiveOrder(tableId);
      if (existingOrder != null) {
        print(
            '⚠️ Table $tableId already has an open order: ${existingOrder.id}');
        await updateTableStatus(tableId, 'occupied');
        return existingOrder;
      }

      final String orderId = _uuid.v4();

      final response = await _client
          .from('orders')
          .insert({
            'id': orderId,
            'table_id': tableId,
            'status': 'open',
            'total': 0.0,
          })
          .select()
          .single();

      print('✅ Order created: ${response['id']}');

      await _client
          .from('tables')
          .update({'status': 'occupied'}).eq('id', tableId);

      print('✅ Table $tableId status set to occupied');

      final verifyTable =
          await _client.from('tables').select().eq('id', tableId).single();

      print(
          '📊 Table ${verifyTable['table_number']} status after update: ${verifyTable['status']}');

      if (verifyTable['status'] != 'occupied') {
        print('⚠️ WARNING: Table status is still ${verifyTable['status']}');
        await _client
            .from('tables')
            .update({'status': 'occupied'}).eq('id', tableId);
      }

      final map = response as Map<String, dynamic>;
      return Order.fromMap(map);
    } catch (e) {
      print('❌ Error in createOrder: $e');
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

// services/supabase_service.dart - Updated getOrderItems

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select('*, products(*)') // This joins the products table
          .eq('order_id', orderId);

      final List<OrderItem> items = [];
      for (var item in response) {
        final map = item as Map<String, dynamic>;

        // Create OrderItem from map
        final orderItem = OrderItem.fromMap(map);

        // If product data is included in the join, create Product object
        if (map['products'] != null) {
          final productMap = map['products'] as Map<String, dynamic>;
          final product = Product.fromMap(productMap);
          orderItem.product = product;
        }

        items.add(orderItem);
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

      final String itemId = _uuid.v4();

      final response = await _client
          .from('order_items')
          .insert({
            'id': itemId,
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

      await updateTableStatus(order.tableId, 'available');

      final map = updatedOrder as Map<String, dynamic>;
      return Order.fromMap(map);
    } catch (e) {
      print('Error in closeOrder: $e');
      throw Exception('Failed to close order: $e');
    }
  }

// services/supabase_service.dart - Updated getCompleteOrder

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

      // Get order items with product data
      final itemsData = await _client
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId);

      final items = <OrderItem>[];
      for (var itemData in itemsData) {
        final map = itemData as Map<String, dynamic>;
        final item = OrderItem.fromMap(map);

        // Add product data if available
        if (map['products'] != null) {
          final productMap = map['products'] as Map<String, dynamic>;
          final product = Product.fromMap(productMap);
          item.product = product;
        }

        items.add(item);
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
  // REPORT METHODS
  // ============================================================

// services/supabase_service.dart - Updated getAllOrders

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, tables(*)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = [];
      for (var orderData in response) {
        final orderMap = orderData as Map<String, dynamic>;

        // Get items for this order with product data
        final itemsData = await _client
            .from('order_items')
            .select('*, products(*)')
            .eq('order_id', orderMap['id']);

        final items = <OrderItem>[];
        for (var itemData in itemsData) {
          final map = itemData as Map<String, dynamic>;
          final item = OrderItem.fromMap(map);

          if (map['products'] != null) {
            final productMap = map['products'] as Map<String, dynamic>;
            final product = Product.fromMap(productMap);
            item.product = product;
          }

          items.add(item);
        }

        // Add items to the order data
        orderMap['items'] = items;
        orders.add(orderMap);
      }
      return orders;
    } catch (e) {
      print('Error in getAllOrders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // services/supabase_service.dart - Helper method

  Future<List<OrderItem>> getOrderItemsWithProducts(String orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId);

      final List<OrderItem> items = [];
      for (var item in response) {
        final map = item as Map<String, dynamic>;

        // Create OrderItem from map
        final orderItem = OrderItem.fromMap(map);

        // If product data is included in the join, create Product object
        if (map['products'] != null) {
          final productMap = map['products'] as Map<String, dynamic>;
          final product = Product.fromMap(productMap);
          orderItem.product = product;
        }

        items.add(orderItem);
      }
      return items;
    } catch (e) {
      print('Error in getOrderItemsWithProducts: $e');
      throw Exception('Failed to fetch order items: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, tables(*)')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = [];
      for (var item in response) {
        orders.add(item as Map<String, dynamic>);
      }
      return orders;
    } catch (e) {
      print('Error in getOrdersByDateRange: $e');
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

  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final totalOrders = await getTotalOrdersCount();
      final todayOrders = await getTodayOrdersCount();
      final totalRevenue = await getTotalRevenue();
      final tables = await getTables();
      final occupiedTables = tables.where((t) => t.isOccupied).length;

      return {
        'totalOrders': totalOrders,
        'todayOrders': todayOrders,
        'totalRevenue': totalRevenue,
        'occupiedTables': occupiedTables,
        'totalTables': tables.length,
      };
    } catch (e) {
      print('Error in getOrderStatistics: $e');
      throw Exception('Failed to get order statistics: $e');
    }
  }
}
