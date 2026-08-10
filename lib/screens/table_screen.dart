import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/supabase_service.dart';
import 'receipt_screen.dart';

class TableScreen extends StatefulWidget {
  final CoffeeTable table;

  const TableScreen({super.key, required this.table});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late CoffeeTable _currentTable;
  Order? _activeOrder;
  List<OrderItem> _orderItems = [];
  bool _isLoading = true;
  String? _error;
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _currentTable = widget.table;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the latest table status
      final tables = await _supabaseService.getTables();
      final updatedTable = tables.firstWhere(
        (t) => t.id == widget.table.id,
        orElse: () => widget.table,
      );

      print(
          '📊 Table ${updatedTable.tableNumber} status: ${updatedTable.status}');
      _currentTable = updatedTable;

      // Get the active order
      final order = await _supabaseService.getActiveOrder(widget.table.id);

      if (order != null) {
        print('✅ Found active order: ${order.id}');
        final items = await _supabaseService.getOrderItems(order.id);

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
        print('ℹ️ No active order for table ${widget.table.tableNumber}');
        setState(() {
          _activeOrder = null;
          _orderItems = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error in _loadData: $e');
      setState(() {
        _error = 'Failed to load order: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTableStatus() async {
    try {
      print('🔄 Refreshing table status...');
      final tables = await _supabaseService.getTables();
      final updatedTable = tables.firstWhere(
        (t) => t.id == widget.table.id,
        orElse: () => widget.table,
      );

      print('📊 Old status: ${_currentTable.status}');
      print('📊 New status: ${updatedTable.status}');

      setState(() {
        _currentTable = updatedTable;
      });
    } catch (e) {
      print('Error refreshing table status: $e');
    }
  }

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

  Future<void> _addItemToOrder(int productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String orderId;
      if (_activeOrder == null) {
        print('🔄 Creating new order for table ${widget.table.id}');
        final order = await _supabaseService.createOrder(widget.table.id);
        orderId = order.id;
        setState(() {
          _activeOrder = order;
        });
        await _refreshTableStatus();
      } else {
        orderId = _activeOrder!.id;
      }

      print('➕ Adding product $productId to order $orderId');
      await _supabaseService.addOrderItem(orderId, productId);

      await _loadData();

      Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
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

  Future<void> _closeOrder() async {
    if (_activeOrder == null) return;

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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        print('🔄 Closing order: ${_activeOrder!.id}');
        final closedOrder = await _supabaseService.closeOrder(_activeOrder!.id);
        print('✅ Order closed: ${closedOrder.id}');

        // CRITICAL: Refresh table status after closing
        await _refreshTableStatus();
        print('📊 Table status after close: ${_currentTable.status}');

        // Get complete order for receipt
        final completeOrder =
            await _supabaseService.getCompleteOrder(closedOrder.id);

        // Dismiss loading
        Navigator.pop(context);

        if (context.mounted) {
          // Navigate to receipt screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(orderData: completeOrder),
            ),
          );

          // After returning from receipt, reload everything
          print('🔄 Returning from receipt, reloading data...');
          await _loadData();
          await _refreshTableStatus();

          // Return true to tell home screen to refresh
          Navigator.pop(context, true);
        }
      } catch (e) {
        Navigator.pop(context);
        print('❌ Error closing order: $e');
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

  void _showQRCode() {
    final qrData = '/#/menu?table=${widget.table.tableNumber}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - Table ${widget.table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan this QR code to view the menu',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Table ${widget.table.tableNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.qr_code),
            onPressed: _showQRCode,
            tooltip: 'Show QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _refreshTableStatus();
              await _loadData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshed!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            tooltip: 'Refresh',
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
          // Status chip - Now showing the correct status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _currentTable.isOccupied
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentTable.isOccupied ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _currentTable.isOccupied ? 'TAKEN 🔴' : 'AVAILABLE 🟢',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _currentTable.isOccupied
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                        ? Colors.blue.shade100
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _activeOrder!.statusDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _activeOrder!.isOpen
                          ? Colors.blue.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                              backgroundColor: Colors.brown.shade100,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown.shade200!),
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
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _activeOrder?.isClosed == true ? null : _showAddItemDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.brown.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                '📝 TAKE ORDER',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (_activeOrder != null &&
                      _activeOrder!.isOpen &&
                      _orderItems.isNotEmpty)
                  ? _closeOrder
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
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
