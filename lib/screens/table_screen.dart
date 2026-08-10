import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/supabase_service.dart';
import 'receipt_screen.dart';

/// The detailed screen for a single table
///
/// Shows:
/// - Table number and status
/// - Current order items
/// - Total
/// - Buttons to Take Order and Close Order
class TableScreen extends StatefulWidget {
  final CoffeeTable table;

  const TableScreen({super.key, required this.table});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  Order? _activeOrder;
  List<OrderItem> _orderItems = [];
  bool _isLoading = true;
  String? _error;
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load the active order and its items
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get the active order for this table
      final order = await _supabaseService.getActiveOrder(widget.table.id);

      if (order != null) {
        // 2. Get items for this order
        final items = await _supabaseService.getOrderItems(order.id);
        // 3. Load product details for each item
        final itemsWithProducts = <OrderItem>[];
        for (var item in items) {
          final product = await _supabaseService.getProductById(item.productId);
          if (product != null) {
            itemsWithProducts.add(OrderItem(
              id: item.id,
              orderId: item.orderId,
              productId: item.productId,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              createdAt: item.createdAt,
              product: product,
            ));
          } else {
            itemsWithProducts.add(item);
          }
        }

        setState(() {
          _activeOrder = order;
          _orderItems = itemsWithProducts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _activeOrder = null;
          _orderItems = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load order: $e';
        _isLoading = false;
      });
    }
  }

  /// Show the dialog to add an item to the order
  Future<void> _showAddItemDialog() async {
    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the Product ID:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Product ID',
                  hintText: 'e.g., 5',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final productId = int.parse(controller.text);
                Navigator.pop(context);
                await _addItemToOrder(productId);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  /// Add an item to the current order
  Future<void> _addItemToOrder(int productId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 1. If no active order, create one
      String orderId;
      if (_activeOrder == null) {
        final order = await _supabaseService.createOrder(widget.table.id);
        orderId = order.id;
        setState(() {
          _activeOrder = order;
        });
      } else {
        orderId = _activeOrder!.id;
      }

      // 2. Add the item
      final item = await _supabaseService.addOrderItem(orderId, productId);

      // 3. Reload the data
      await _loadData();

      // Dismiss loading and show success
      Navigator.pop(context);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading
      Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Close the current order
  Future<void> _closeOrder() async {
    if (_activeOrder == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Close order for Table ${widget.table.tableNumber}?'),
            const SizedBox(height: 8),
            Text(
              'Total: \$${_activeOrder!.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Close Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Close the order
        final closedOrder = await _supabaseService.closeOrder(_activeOrder!.id);

        // Dismiss loading
        Navigator.pop(context);

        // Get complete order details for receipt
        final completeOrder =
            await _supabaseService.getCompleteOrder(closedOrder.id);

        // Navigate to receipt screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(orderData: completeOrder),
            ),
          ).then((_) {
            // When coming back from receipt, reload data
            _loadData();
          });
        }
      } catch (e) {
        Navigator.pop(context); // Dismiss loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to close order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Table ${widget.table.tableNumber}'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.table.isOccupied
                  ? Colors.orange[100]
                  : Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Status: ${widget.table.statusDisplay}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.table.isOccupied
                    ? Colors.orange[800]
                    : Colors.green[800],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order section
          if (_activeOrder != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${_activeOrder!.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _activeOrder!.isOpen
                        ? Colors.blue[100]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _activeOrder!.statusDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _activeOrder!.isOpen
                          ? Colors.blue[800]
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order items list
            Expanded(
              child: _orderItems.isEmpty
                  ? const Center(
                      child: Text('No items yet. Add items to this order.'),
                    )
                  : ListView.builder(
                      itemCount: _orderItems.length,
                      itemBuilder: (context, index) {
                        final item = _orderItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.brown[100],
                              child: Text('${item.quantity}×'),
                            ),
                            title: Text(
                              item.product?.name ?? 'Product ${item.productId}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text('ID: ${item.productId}'),
                            trailing: Text(
                              '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${(_activeOrder?.total ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active order',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Text(
                      'Tap "Take Order" to start',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Take Order Button
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _activeOrder?.isClosed == true ? null : _showAddItemDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                '📝 TAKE ORDER',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Close Order Button
          Expanded(
            child: ElevatedButton(
              onPressed: (_activeOrder != null &&
                      _activeOrder!.isOpen &&
                      _orderItems.isNotEmpty)
                  ? _closeOrder
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                '🧾 CLOSE ORDER',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
