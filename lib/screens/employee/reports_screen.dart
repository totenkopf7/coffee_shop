import 'package:coffee_shop/core/config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/order_with_items.dart';
import '../../services/supabase_service.dart';
import '../../widgets/background_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = SupabaseService.instance;

  String _period = 'daily';
  bool _loading = true;
  String? _error;
  List<OrderWithItems> _orders = [];
  double _revenue = 0;
  int _closedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _rangeStart() {
    final now = DateTime.now();
    switch (_period) {
      case 'weekly':
        final d = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(d.year, d.month, d.day);
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      case 'daily':
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getOrdersInRange(
        from: _rangeStart(),
        to: DateTime.now(),
      );

      final closed = list.where((o) => o.order.isClosed).toList();
      final revenue = closed.fold<double>(0, (s, o) => s + o.order.total);

      if (!mounted) return;
      setState(() {
        _orders = list;
        _revenue = revenue;
        _closedCount = closed.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Reports'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ],
        ),
        body: Column(
          children: [
            _periodSelector(),
            if (_loading)
              const Expanded(
                  child: LoadingWidget(message: 'Loading reports...'))
            else if (_error != null)
              Expanded(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load reports',
                  subtitle: _error,
                  action: ElevatedButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ),
              )
            else ...[
              _statsRow(),
              Expanded(
                child: _orders.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long,
                        title: 'No orders in this period',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) {
                          final r = _orders[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                'Order #${r.order.id.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Table ${r.order.tableId} · '
                                '${DateFormat('MMM d, h:mm a').format(r.order.createdAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                AppConfig.money(r.order.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _periodSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'daily', label: Text('Daily')),
          ButtonSegment(value: 'weekly', label: Text('Weekly')),
          ButtonSegment(value: 'monthly', label: Text('Monthly')),
        ],
        selected: {_period},
        onSelectionChanged: (s) {
          setState(() => _period = s.first);
          _load();
        },
      ),
    );
  }

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child:
                _stat('Revenue', AppConfig.money(_revenue), AppColors.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _stat('Closed Orders', '$_closedCount', AppColors.info),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _stat(
              'Avg',
              AppConfig.money(
                  _closedCount == 0 ? 0 : (_revenue / _closedCount)),
              AppColors.caramel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
