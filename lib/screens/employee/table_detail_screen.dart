// screens\employee\table_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../models/coffee_table.dart';
import '../../models/order_with_items.dart';
import '../../models/product.dart';
import '../../models/table_session.dart';
import '../../services/supabase_service.dart';
import '../../widgets/background_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'open_table_dialog.dart';
import 'receipt_screen.dart';

class TableDetailScreen extends StatefulWidget {
  final CoffeeTable table;
  final TableSession session;

  const TableDetailScreen({
    super.key,
    required this.table,
    required this.session,
  });

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  final _service = SupabaseService.instance;

  bool _loading = true;
  String? _error;
  List<OrderWithItems> _rounds = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rounds = await _service.getOrdersForSession(widget.session.id);
      if (!mounted) return;
      setState(() {
        _rounds = rounds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load orders: $e';
        _loading = false;
      });
    }
  }

  void _subscribe() {
    _service.watchOrdersForSession(widget.session.id).listen(
      (rounds) {
        if (!mounted) return;
        if (_rounds.length == rounds.length &&
            _sameSignature(_rounds, rounds)) {
          return;
        }
        setState(() => _rounds = rounds);
      },
      onError: (e) => debugPrint('watchOrdersForSession error: $e'),
    );
  }

  bool _sameSignature(List<OrderWithItems> a, List<OrderWithItems> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].order.id != b[i].order.id) return false;
      if (a[i].items.length != b[i].items.length) return false;
      for (var j = 0; j < a[i].items.length; j++) {
        if (a[i].items[j].id != b[i].items[j].id) return false;
        if (a[i].items[j].quantity != b[i].items[j].quantity) return false;
      }
    }
    return true;
  }

  double get _total => _rounds.fold(0.0, (sum, r) => sum + r.order.total);

  int get _itemCount => _rounds.fold(0, (sum, r) => sum + r.itemCount);

  Future<void> _close() async {
    final ok = await showCloseTableDialog(
      context,
      widget.table.tableNumber,
      _total,
      _rounds.length,
    );
    if (ok != true) return;

    final snapshot = List<OrderWithItems>.from(_rounds);

    try {
      await _service.closeTable(widget.session.id);
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            table: widget.table,
            rounds: snapshot,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close table: $e')),
      );
    }
  }

  Future<void> _staffAddItems() async {
    final products = await _service.getAvailableProducts();
    if (!mounted) return;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available')),
      );
      return;
    }
    final picked = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffAddSheet(products: products),
    );

    if (picked == null || picked.isEmpty) return;

    try {
      await _service.addStaffOrder(
        sessionId: widget.session.id,
        tableId: widget.table.id,
        items: picked,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add order: $e')),
      );
    }
  }

  void _showQr() {
    // Use the runtime customer base URL — on Vercel this becomes
    // https://your-app.vercel.app, on LAN it becomes http://192.168.x.x:5004,
    // etc. Always points at a URL that the cashier's device just loaded,
    // so it is guaranteed reachable from a phone on the same network.
    final qrText = AppConstants.customerMenuUrlFor(widget.table.tableNumber);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QR — Table ${widget.table.tableNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: QrImageView(
                    data: qrText,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.espresso,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Table ${widget.table.tableNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  qrText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Point the customer at this QR to open the menu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          actions: [
            IconButton(
              tooltip: 'Show QR',
              icon: const Icon(Icons.qr_code_2),
              onPressed: _showQr,
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ],
        ),
        body: _loading
            ? const LoadingWidget(message: 'Loading orders...')
            : _error != null
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load orders',
                    subtitle: _error,
                    action: ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  )
                : _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildStatusHeader(),
        Expanded(
          child: _rounds.isEmpty
              ? const EmptyState(
                  icon: Icons.hourglass_empty,
                  title: 'No orders yet',
                  subtitle:
                      'The customer will place their first order from the QR menu.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _rounds.length,
                  itemBuilder: (_, i) => _RoundCard(round: _rounds[i]),
                ),
        ),
        _buildTotalBox(),
      ],
    );
  }

  Widget _buildStatusHeader() {
    final isCheck = widget.session.isCheckRequested;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isCheck ? AppColors.dangerLight : AppColors.successLight,
      child: Row(
        children: [
          Icon(
            isCheck ? Icons.notifications_active : Icons.qr_code_2,
            color: isCheck ? AppColors.danger : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCheck
                  ? 'Customer requested the check — bring the bill.'
                  : 'QR is live. Customer can order.',
              style: TextStyle(
                color: isCheck ? AppColors.danger : AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_itemCount item${_itemCount == 1 ? '' : 's'} · '
                '${_rounds.length} round${_rounds.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            '\$${_total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.espresso,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Items'),
                onPressed: _staffAddItems,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Close Table'),
                onPressed: _close,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final OrderWithItems round;
  const _RoundCard({required this.round});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coffee,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ROUND ${round.order.roundNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  round.order.statusDisplay,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...round.items.map(
              (it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${it.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        it.displayName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '\$${it.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${round.itemCount} items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Round total: \$${round.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.espresso,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet used by staff to add products to the current session.
class _StaffAddSheet extends StatefulWidget {
  final List<Product> products;
  const _StaffAddSheet({required this.products});

  @override
  State<_StaffAddSheet> createState() => _StaffAddSheetState();
}

class _StaffAddSheetState extends State<_StaffAddSheet> {
  final Map<int, int> _qty = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.foam,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add items for staff order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.products.length,
                  itemBuilder: (_, i) {
                    final p = widget.products[i];
                    final q = _qty[p.id] ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.formattedPrice),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: q == 0
                                  ? null
                                  : () => setState(() => _qty[p.id] = q - 1),
                            ),
                            Text(
                              '$q',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  setState(() => _qty[p.id] = q + 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _qty.values.every((v) => v == 0)
                          ? null
                          : () {
                              final items = <Map<String, dynamic>>[];
                              for (final p in widget.products) {
                                final q = _qty[p.id] ?? 0;
                                if (q > 0) {
                                  items.add({
                                    'productId': p.id,
                                    'quantity': q,
                                    'unitPrice': p.price,
                                  });
                                }
                              }
                              Navigator.pop(context, items);
                            },
                      child: const Text('Add to Order'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
