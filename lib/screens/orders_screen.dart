// screens/orders_screen.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/coffee_table.dart';
import '../widgets/background_widget.dart';
import '../widgets/loading_widget.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  final SupabaseService _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getAllOrders();

      final List<Map<String, dynamic>> processedOrders = [];
      for (var orderData in response) {
        final order = Order.fromMap(orderData);
        final table = CoffeeTable.fromMap(orderData['tables']);

        final items = await _service.getOrderItems(order.id);

        processedOrders.add({
          'order': order,
          'table': table,
          'items': items,
          'itemCount': items.length,
        });
      }

      setState(() {
        _orders = processedOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('📋 Orders'),
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadOrders,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading orders...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No orders yet'),
            SizedBox(height: 8),
            Text(
              'Orders will appear here once customers order',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final data = _orders[index];
        final order = data['order'] as Order;
        final table = data['table'] as CoffeeTable;
        final items = data['items'] as List<OrderItem>;
        final itemCount = data['itemCount'] as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    order.isOpen ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                order.isOpen ? Icons.access_time : Icons.check_circle,
                color:
                    order.isOpen ? Colors.green.shade700 : Colors.grey.shade600,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Text(
                  'Table ${table.tableNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: table.isOccupied
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    table.isOccupied ? 'TAKEN' : 'AVAILABLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: table.isOccupied
                          ? Colors.red.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.isOpen
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: order.isOpen
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${itemCount} items · \$${order.total.toStringAsFixed(2)}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '${item.quantity}×',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.product?.name ??
                                      'Product ${item.productId}',
                                ),
                              ),
                              Text(
                                '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (order.closedAt != null)
                          Text(
                            'Closed: ${_formatDate(order.closedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
