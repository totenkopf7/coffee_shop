// screens/table_screen.dart
import 'package:coffee_shop/models/product.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/supabase_service.dart';
import '../widgets/background_widget.dart';
import '../widgets/loading_widget.dart';
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
  final SupabaseService _supabaseService = SupabaseService();

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
      final tables = await _supabaseService.getTables();
      final updatedTable = tables.firstWhere(
        (t) => t.id == widget.table.id,
        orElse: () => widget.table,
      );

      print(
          '📊 Table ${updatedTable.tableNumber} status: ${updatedTable.status}');
      _currentTable = updatedTable;

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
    final products = await _supabaseService.getProducts();

    if (products.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products available. Please add products first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📋 Select Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductMenuItem(product);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductMenuItem(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _addItemToOrder(product.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildProductImage(product),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                product.formattedPrice,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.brown[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    final imageUrl = product.imageUrl ??
        'https://images.unsplash.com/photo-1504753793650-d4a2b783c15e?w=200&h=200&fit=crop';

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 30, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                'No Image',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addItemToOrder(int productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingWidget(message: 'Adding item...'),
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
        builder: (context) => const LoadingWidget(message: 'Closing order...'),
      );

      try {
        print('🔄 Closing order: ${_activeOrder!.id}');
        final closedOrder = await _supabaseService.closeOrder(_activeOrder!.id);
        print('✅ Order closed: ${closedOrder.id}');

        await _refreshTableStatus();
        print('📊 Table status after close: ${_currentTable.status}');

        final completeOrder =
            await _supabaseService.getCompleteOrder(closedOrder.id);

        Navigator.pop(context);

        if (context.mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(orderData: completeOrder),
            ),
          );

          print('🔄 Returning from receipt, reloading data...');
          await _loadData();
          await _refreshTableStatus();
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
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Table ${widget.table.tableNumber}'),
          backgroundColor: Colors.brown[800]?.withOpacity(0.92),
          foregroundColor: Colors.white,
          elevation: 4,
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
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading order...');
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No items yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Tap "Take Order" to add items',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _orderItems.length,
                      itemBuilder: (context, index) {
                        final item = _orderItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.brown.shade100,
                              child: Text(
                                '${item.quantity}×',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown.shade800,
                                ),
                              ),
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
                                color: Colors.brown,
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
                color: Colors.brown.shade50.withOpacity(0.92),
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
        color: Colors.white.withOpacity(0.95),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
