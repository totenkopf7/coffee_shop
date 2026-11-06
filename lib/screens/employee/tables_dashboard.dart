// screens/employee/tables_dashboard.dart
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../core/locale_provider.dart';
import '../../models/coffee_table.dart';
import '../../models/order.dart';
import '../../models/table_session.dart';
import '../../services/auth_service.dart';
import '../../services/sound_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/background_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/table_card.dart';
import 'employee_login_screen.dart';
import 'menu_management_screen.dart';
import 'open_table_dialog.dart';
import 'reports_screen.dart';
import 'table_detail_screen.dart';

class TablesDashboard extends StatefulWidget {
  const TablesDashboard({super.key});

  @override
  State<TablesDashboard> createState() => _TablesDashboardState();
}

class _TablesDashboardState extends State<TablesDashboard> {
  final _service = SupabaseService.instance;

  bool _loading = true;
  String? _error;

  List<CoffeeTable> _tables = [];
  List<TableSession> _sessions = [];
  List<Order> _allOrders = [];

  final Set<String> _alertedCheckSessions = {};
  final Set<String> _alertedOrderIds = {};
  final Set<String> _sessionsWithNewOrders = {};

  DateTime _dashboardOpenedAt = DateTime.now();
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _dashboardOpenedAt = DateTime.now();
    _loadInitial();
    _subscribeTables();
    _subscribeSessions();
    _subscribeOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getTables(),
        _service.getAllSessions(),
        _service.getAllOrders(),
      ]);
      if (!mounted) return;
      final tables = results[0] as List<CoffeeTable>;
      final sessions = results[1] as List<TableSession>;
      final orders = results[2] as List<Order>;

      for (final o in orders) {
        if (o.createdAt.isBefore(_dashboardOpenedAt)) {
          _alertedOrderIds.add(o.id);
        }
      }
      for (final s in sessions) {
        if (s.isCheckRequested) _alertedCheckSessions.add(s.id);
      }

      setState(() {
        _tables = tables;
        _sessions = sessions;
        _allOrders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load tables: $e';
        _loading = false;
      });
    }
  }

  void _subscribeTables() {
    _service.watchTables().listen(
      (rows) {
        if (!mounted) return;
        setState(() => _tables = rows);
      },
      onError: (e) => debugPrint('watchTables error: $e'),
    );
  }

  void _subscribeSessions() {
    _service.watchAllSessions().listen(
      (sessions) {
        if (!mounted) return;
        setState(() => _sessions = sessions);
        _checkCheckAlerts(sessions);
      },
      onError: (e) => debugPrint('watchSessions error: $e'),
    );
  }

  void _subscribeOrders() {
    _service.watchAllOrders().listen(
      (orders) {
        if (!mounted) return;
        setState(() => _allOrders = orders);
        _checkOrderAlerts(orders);
      },
      onError: (e) => debugPrint('watchAllOrders error: $e'),
    );
  }

  void _checkCheckAlerts(List<TableSession> sessions) {
    for (final s in sessions) {
      if (s.isCheckRequested && !_alertedCheckSessions.contains(s.id)) {
        _alertedCheckSessions.add(s.id);
        SoundService.instance.playCheckRequest();
        _showAlert(
          icon: Icons.notifications_active,
          text: 'Table #${s.tableNumber} requested the check.',
          color: AppColors.danger,
        );
      }
      if (s.isClosed) {
        _alertedCheckSessions.remove(s.id);
        _sessionsWithNewOrders.remove(s.id);
      }
    }
  }

  void _checkOrderAlerts(List<Order> orders) {
    for (final o in orders) {
      if (o.sessionId == null) continue;
      if (o.isClosed) continue;
      if (_alertedOrderIds.contains(o.id)) continue;

      if (o.createdAt.isBefore(_dashboardOpenedAt)) {
        _alertedOrderIds.add(o.id);
        continue;
      }

      final session = _sessionById(o.sessionId!);
      if (session == null) continue;

      if (session.isClosed) {
        _alertedOrderIds.add(o.id);
        continue;
      }

      _alertedOrderIds.add(o.id);
      _sessionsWithNewOrders.add(o.sessionId!);
      SoundService.instance.playNewOrder();
      _showAlert(
        icon: Icons.receipt_long,
        text: 'New order on table #${session.tableNumber}.',
        color: AppColors.caramel,
      );
    }
  }

  void _showAlert({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final messenger = _messenger ?? ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableSession? _sessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  TableSession? _sessionForTable(int tableNumber) {
    try {
      return _sessions
          .firstWhere((s) => s.tableNumber == tableNumber && !s.isClosed);
    } catch (_) {
      return null;
    }
  }

  List<Order> _ordersForSession(String sessionId) =>
      _allOrders.where((o) => o.sessionId == sessionId && !o.isClosed).toList();

  TableVisualState _visualState(CoffeeTable t) {
    final session = _sessionForTable(t.tableNumber);
    if (session == null || !t.isOpen) return TableVisualState.closed;
    if (session.isCheckRequested) return TableVisualState.checkRequested;
    final orders = _ordersForSession(session.id);
    if (orders.isEmpty) return TableVisualState.open;
    return TableVisualState.ordering;
  }

  Future<void> _onTableTap(CoffeeTable t) async {
    final state = _visualState(t);

    if (state == TableVisualState.closed) {
      final ok = await showOpenTableDialog(context, t.tableNumber);
      if (ok != true) return;
      try {
        await _service.openTable(t.tableNumber);
        await _loadInitial();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open table: $e')),
        );
      }
      return;
    }

    final session = _sessionForTable(t.tableNumber);
    if (session == null) return;

    _sessionsWithNewOrders.remove(session.id);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TableDetailScreen(table: t, session: session),
      ),
    );
  }

  Future<void> _logout() async {
    final t = AppLocalizations.t(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(t.logOut),
        content: Text(t.logOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.logOut),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmployeeLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.t(context);
    final openCount = _tables.where((x) => x.isOpen).length;
    final checksNeeded = _sessions.where((s) => s.isCheckRequested).length;

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: _buildDrawer(context),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(t.appTitle),
                  if (checksNeeded > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⚠️ $checksNeeded',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '$openCount ${t.ofWord} ${_tables.length} ${t.openTables}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: t.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _loadInitial();
              },
            ),
            PopupMenuButton<String>(
              tooltip: 'Account',
              icon: const Icon(Icons.account_circle),
              onSelected: (v) {
                if (v == 'logout') _logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Signed in as ${AuthService.instance.displayName ?? AuthService.instance.username ?? 'staff'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 18),
                      const SizedBox(width: 8),
                      Text(t.logOut),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildBody(checksNeeded),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final t = AppLocalizations.t(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Drawer header with logo ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            color: AppColors.espresso,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/coffeeshop_logo.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      '☕',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t.appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Signed in: ${AuthService.instance.displayName ?? AuthService.instance.username ?? 'staff'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant),
            title: Text(t.tables),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text(t.menuManagement),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MenuManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(t.reports),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language / زمان'),
            onTap: () {
              Navigator.pop(context);
              showLanguagePicker(context, localeProviderInstance);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: Text(
              t.logOut,
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int checksNeeded) {
    final t = AppLocalizations.t(context);
    if (_loading) {
      return LoadingWidget(message: t.loadLoadingTables);
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load tables',
        subtitle: _error,
        action: ElevatedButton(
          onPressed: _loadInitial,
          child: Text(t.retry),
        ),
      );
    }

    if (_tables.isEmpty) {
      return const EmptyState(
        icon: Icons.table_restaurant,
        title: 'No tables configured',
        subtitle: 'Add tables in Supabase to get started.',
      );
    }

    return Column(
      children: [
        if (checksNeeded > 0) _buildAttentionBanner(checksNeeded),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
            ),
            itemCount: _tables.length,
            itemBuilder: (_, i) {
              final tb = _tables[i];
              final session = _sessionForTable(tb.tableNumber);
              final orders =
                  session == null ? <Order>[] : _ordersForSession(session.id);
              final total = orders.fold<double>(0, (sum, o) => sum + o.total);
              final hasNewOrder = session != null &&
                  _sessionsWithNewOrders.contains(session.id);

              return TableCard(
                table: tb,
                state: _visualState(tb),
                orderCount: orders.length,
                runningTotal: total,
                isCheckRequested: session?.isCheckRequested ?? false,
                hasNewOrder: hasNewOrder,
                onTap: () => _onTableTap(tb),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionBanner(int count) {
    final t = AppLocalizations.t(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? t.tableWaitingCheck
                  : '$count ${t.tablesWaitingCheck}',
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
