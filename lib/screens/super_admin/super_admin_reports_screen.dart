// screens/super_admin/super_admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../employee/employee_login_screen.dart';
import '../../core/app_localizations.dart';
import '../../core/locale_provider.dart';
import '../../widgets/language_picker.dart';

class SuperAdminReportsScreen extends StatefulWidget {
  const SuperAdminReportsScreen({super.key});
  @override
  State<SuperAdminReportsScreen> createState() =>
      _SuperAdminReportsScreenState();
}

class _SuperAdminReportsScreenState extends State<SuperAdminReportsScreen> {
  final _client = Supabase.instance.client;

  String _period = 'daily';
  DateTime _anchor = DateTime.now();

  bool _loading = true;
  String? _error;

  double _revenue = 0;
  int _orderCount = 0;
  int _itemCount = 0;
  int _uniqueTables = 0;
  double _avgOrder = 0;

  final Map<int, _TableStat> _perTable = {};
  final Map<int, int> _tableNumberById = {};
  final Map<String, int> _perProductQty = {};
  final Map<String, double> _breakdown = {};
  List<_SessionRow> _sessions = [];

  DateTime get _rangeStart {
    if (_period == 'monthly') return DateTime(_anchor.year, _anchor.month, 1);
    return DateTime(_anchor.year, _anchor.month, _anchor.day);
  }

  DateTime get _rangeEnd {
    if (_period == 'monthly') {
      final next = DateTime(_anchor.year, _anchor.month + 1, 1);
      return next.subtract(const Duration(seconds: 1));
    }
    return DateTime(_anchor.year, _anchor.month, _anchor.day, 23, 59, 59);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _revenue = 0;
      _orderCount = 0;
      _itemCount = 0;
      _uniqueTables = 0;
      _avgOrder = 0;
      _perTable.clear();
      _tableNumberById.clear();
      _perProductQty.clear();
      _breakdown.clear();
      _sessions = [];
    });

    try {
      final fromUtc = _rangeStart.toUtc().toIso8601String();
      final toUtc = _rangeEnd.toUtc().toIso8601String();

      // Table number lookup
      final tableRows = await _client.from('tables').select('id, table_number');
      for (final t in tableRows) {
        _tableNumberById[(t['id'] as num).toInt()] =
            (t['table_number'] as num).toInt();
      }

      // Orders in range
      final orderRows = await _client
          .from('orders')
          .select('id, table_id, total, created_at, status')
          .gte('created_at', fromUtc)
          .lte('created_at', toUtc);

      final orders = (orderRows as List).cast<Map<String, dynamic>>();
      _orderCount = orders.length;

      final orderIds = <String>[];
      final tableIds = <int>{};
      for (final o in orders) {
        orderIds.add(o['id'] as String);
        final tid = (o['table_id'] as num).toInt();
        tableIds.add(tid);
        final total = (o['total'] as num?)?.toDouble() ?? 0;
        _revenue += total;

        _perTable.putIfAbsent(tid, () => _TableStat());
        _perTable[tid]!.orderCount++;
        _perTable[tid]!.revenue += total;

        final created = DateTime.parse(o['created_at'] as String).toLocal();
        final key = _period == 'monthly'
            ? DateFormat('yyyy-MM-dd').format(created)
            : '${created.hour.toString().padLeft(2, '0')}:00';
        _breakdown[key] = (_breakdown[key] ?? 0) + total;
      }
      _uniqueTables = tableIds.length;
      _avgOrder = _orderCount == 0 ? 0 : _revenue / _orderCount;

      // Items — select product name via join. Schema has NO name_snapshot.
      if (orderIds.isNotEmpty) {
        const chunkSize = 500;
        for (var i = 0; i < orderIds.length; i += chunkSize) {
          final chunk = orderIds.sublist(
            i,
            i + chunkSize > orderIds.length ? orderIds.length : i + chunkSize,
          );
          final itemRows = await _client
              .from('order_items')
              .select('order_id, quantity, products(name)')
              .inFilter('order_id', chunk);

          final items = (itemRows as List).cast<Map<String, dynamic>>();
          for (final it in items) {
            final qty = (it['quantity'] as num?)?.toInt() ?? 0;
            _itemCount += qty;
            final prod = it['products'];
            final name = prod is Map
                ? ((prod['name'] as String?) ?? 'Unknown')
                : 'Unknown';
            _perProductQty[name] = (_perProductQty[name] ?? 0) + qty;
          }
        }
      }

      // Sessions in range
      final sessionRows = await _client
          .from('table_sessions')
          .select('id, table_id, table_number, opened_at, closed_at, status')
          .gte('opened_at', fromUtc)
          .lte('opened_at', toUtc)
          .order('opened_at', ascending: false);

      final sessions = (sessionRows as List).cast<Map<String, dynamic>>();
      _sessions = sessions.map((s) {
        final opened = DateTime.parse(s['opened_at'] as String).toLocal();
        final closed = s['closed_at'] != null
            ? DateTime.parse(s['closed_at'] as String).toLocal()
            : null;
        return _SessionRow(
          id: s['id'] as String,
          tableNumber: (s['table_number'] as num).toInt(),
          openedAt: opened,
          closedAt: closed,
          status: (s['status'] as String?) ?? 'open',
        );
      }).toList();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load report: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    if (_period == 'daily') {
      final picked = await showDatePicker(
        context: context,
        initialDate: _anchor,
        firstDate: DateTime(2024),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (picked == null) return;
      setState(() => _anchor = picked);
    } else {
      final year = await showDialog<int>(
        context: context,
        builder: (ctx) => _YearPickerDialog(initialYear: _anchor.year),
      );
      if (year == null) return;
      final month = await showDialog<int>(
        context: context,
        builder: (ctx) =>
            _MonthPickerDialog(initialMonth: _anchor.month, year: year),
      );
      if (month == null) return;
      setState(() => _anchor = DateTime(year, month, 1));
    }
    _load();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmployeeLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Super Admin Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            tooltip: 'Language / زمان',
            icon: const Icon(Icons.language),
            onPressed: () =>
                showLanguagePicker(context, localeProviderInstance),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _topControls(),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(child: _errorView())
          else
            Expanded(child: _reportBody()),
        ],
      ),
    );
  }

  Widget _topControls() {
    final label = _period == 'monthly'
        ? DateFormat('MMMM yyyy').format(_anchor)
        : DateFormat('EEE, MMM d, y').format(_anchor);
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ],
              selected: {_period},
              onSelectionChanged: (s) {
                setState(() => _period = s.first);
                _load();
              },
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(label),
            onPressed: _pickDate,
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _reportBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _statsGrid(),
        const SizedBox(height: 16),
        _mostUsedTable(),
        const SizedBox(height: 16),
        _topProducts(),
        const SizedBox(height: 16),
        _breakdownCard(),
        const SizedBox(height: 16),
        _tableActivity(),
      ],
    );
  }

  Widget _statsGrid() {
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth < 620;
        final cards = [
          _Stat(
            label: 'Revenue',
            value: '\$${_revenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: AppColors.success,
          ),
          _Stat(
            label: 'Orders',
            value: '$_orderCount',
            icon: Icons.receipt_long,
            color: AppColors.caramel,
          ),
          _Stat(
            label: 'Items Sold',
            value: '$_itemCount',
            icon: Icons.local_cafe,
            color: AppColors.coffee,
          ),
          _Stat(
            label: 'Avg Order',
            value: '\$${_avgOrder.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: AppColors.info,
          ),
        ];
        return GridView.count(
          crossAxisCount: twoCols ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: cards.map(_statCard).toList(),
        );
      },
    );
  }

  Widget _statCard(_Stat s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(s.icon, color: s.color, size: 20),
          const Spacer(),
          Text(
            s.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.espresso,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            s.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mostUsedTable() {
    int? topId;
    int topCount = 0;
    _perTable.forEach((id, s) {
      if (s.orderCount > topCount) {
        topCount = s.orderCount;
        topId = id;
      }
    });
    final tableNo = topId == null ? null : _tableNumberById[topId];
    final topLabel = topId == null
        ? '—'
        : 'Table #${tableNo ?? topId} • $topCount order${topCount == 1 ? '' : 's'}';
    final topRevenue = topId == null ? 0.0 : _perTable[topId]!.revenue;

    return _card(
      title: 'Most-used table',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.table_restaurant, color: AppColors.espresso),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Revenue \$${topRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_uniqueTables table${_uniqueTables == 1 ? '' : 's'} used',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topProducts() {
    final entries = _perProductQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    return _card(
      title: 'Top products',
      child: top.isEmpty
          ? const Text(
              'No products sold in this range.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: top.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${e.value} sold',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.caramel,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _breakdownCard() {
    final entries = _breakdown.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = entries.fold<double>(1, (m, e) => e.value > m ? e.value : m);

    return _card(
      title: _period == 'monthly' ? 'Revenue per day' : 'Revenue per hour',
      child: entries.isEmpty
          ? const Text(
              'No data for this period.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: entries.map((e) {
                final ratio = e.value / maxVal;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 78,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio.clamp(0.02, 1.0),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.caramel,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '\$${e.value.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.espresso,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _tableActivity() {
    if (_sessions.isEmpty) {
      return _card(
        title: 'Table activity',
        child: const Text(
          'No sessions opened in this period.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return _card(
      title: 'Table activity (${_sessions.length})',
      child: Column(
        children: _sessions.take(30).map((s) {
          final dur =
              s.closedAt == null ? null : s.closedAt!.difference(s.openedAt);
          final durText = dur == null ? 'still open' : '${dur.inMinutes} min';
          final color =
              s.closedAt == null ? AppColors.success : AppColors.textSecondary;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${s.tableNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d • h:mm a').format(s.openedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        s.closedAt == null
                            ? 'open now'
                            : 'closed ${DateFormat('h:mm a').format(s.closedAt!)}',
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ],
                  ),
                ),
                Text(
                  durText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.espresso,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _TableStat {
  int orderCount = 0;
  double revenue = 0;
}

class _SessionRow {
  final String id;
  final int tableNumber;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String status;
  const _SessionRow({
    required this.id,
    required this.tableNumber,
    required this.openedAt,
    required this.closedAt,
    required this.status,
  });
}

class _YearPickerDialog extends StatelessWidget {
  final int initialYear;
  const _YearPickerDialog({required this.initialYear});
  @override
  Widget build(BuildContext context) {
    final years = List.generate(6, (i) => DateTime.now().year - 5 + i);
    return AlertDialog(
      title: const Text('Select year'),
      content: SizedBox(
        width: 240,
        child: ListView(
          shrinkWrap: true,
          children: years.map((y) {
            return ListTile(
              title: Text('$y'),
              selected: y == initialYear,
              onTap: () => Navigator.pop(context, y),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _MonthPickerDialog extends StatelessWidget {
  final int initialMonth;
  final int year;
  const _MonthPickerDialog({required this.initialMonth, required this.year});
  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return AlertDialog(
      title: Text('Select month — $year'),
      content: SizedBox(
        width: 300,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: months.asMap().entries.map((e) {
            final m = e.key + 1;
            final selected = m == initialMonth;
            return InkWell(
              onTap: () => Navigator.pop(context, m),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.espresso : AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.espresso,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
