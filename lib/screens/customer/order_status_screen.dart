// screens/customer/order_status_screen.dart
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../core/config.dart';
import '../../models/coffee_table.dart';
import '../../models/order_with_items.dart';
import '../../models/table_session.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'customer_menu_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  final CoffeeTable table;
  final TableSession session;
  final String? placedOrderId;

  const OrderStatusScreen({
    super.key,
    required this.table,
    required this.session,
    this.placedOrderId,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final _service = SupabaseService.instance;

  bool _loading = true;
  String? _error;
  List<OrderWithItems> _rounds = [];
  TableSession? _liveSession;
  bool _requestingCheck = false;

  @override
  void initState() {
    super.initState();
    _liveSession = widget.session;
    _load();
    _subscribeOrders();
    _subscribeSession();
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
        _error = 'Failed to load your order: $e';
        _loading = false;
      });
    }
  }

  void _subscribeOrders() {
    _service.watchOrdersForSession(widget.session.id).listen(
      (rounds) {
        if (!mounted) return;
        if (_rounds.length == rounds.length &&
            _sameSignature(_rounds, rounds)) {
          return;
        }
        setState(() => _rounds = rounds);
      },
      onError: (e) => debugPrint('watchOrders error: $e'),
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

  void _subscribeSession() {
    _service.watchSession(widget.session.id).listen(
      (s) {
        if (!mounted || s == null) return;
        setState(() => _liveSession = s);
      },
      onError: (e) => debugPrint('watchSession error: $e'),
    );
  }

  double get _total => _rounds.fold(0.0, (s, r) => s + r.order.total);

  Future<void> _orderMore() async {
    final s = _liveSession;
    if (s == null || !s.isOpen) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerMenuScreen(
          table: widget.table,
          session: s,
        ),
      ),
    );
    await _load();
  }

  Future<void> _requestCheck() async {
    final s = _liveSession;
    if (s == null || !s.isOpen) return;
    if (_requestingCheck) return;

    final t = AppLocalizations.t(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(t.requestCheckTitle),
        content: Text(t.requestCheckBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.requestCheck),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _requestingCheck = true);
    try {
      await _service.requestCheck(s.id);
      if (!mounted) return;
      final updated = await _service.getSessionById(s.id);
      if (!mounted) return;
      if (updated != null) setState(() => _liveSession = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.t(context).checkRequestedSnack),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request check: $e')),
      );
    } finally {
      if (mounted) setState(() => _requestingCheck = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _liveSession;
    final isCheck = session?.isCheckRequested ?? false;
    final canOrderMore = session?.isOpen ?? false;

    return Scaffold(
      backgroundColor: AppColors.foam,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Table ${widget.table.tableNumber}'),
            if (isCheck) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active,
                        size: 11, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'CHECK',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.espresso,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Back to menu',
            icon: const Icon(Icons.restaurant_menu),
            onPressed: _orderMore,
          ),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Loading your order...')
          : _error != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Something went wrong',
                  subtitle: _error,
                  action: ElevatedButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                )
              : _rounds.isEmpty
                  ? EmptyState(
                      icon: Icons.hourglass_empty,
                      title: 'No orders yet',
                      subtitle:
                          'Your order will appear here as soon as it is placed.',
                      action: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Order something'),
                        onPressed: _orderMore,
                      ),
                    )
                  : _buildList(isCheck),
      bottomNavigationBar: _buildBottomBar(isCheck, canOrderMore),
    );
  }

  Widget _buildList(bool isCheck) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        if (isCheck)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_active, color: AppColors.danger),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Check requested. Please wait for the staff. '
                    'You can still order more.',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ..._rounds.map((r) => _RoundBlock(round: r)),
      ],
    );
  }

  Widget _buildBottomBar(bool isCheck, bool canOrderMore) {
    final t = AppLocalizations.t(context);

    ButtonStyle solidButtonStyle({
      required Color background,
      required Color disabledBackground,
    }) {
      return ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return disabledBackground;
          }
          return background;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.white70;
          }
          return Colors.white;
        }),
        iconColor: MaterialStateProperty.all(Colors.white),
        overlayColor: MaterialStateProperty.all(
          Colors.white.withOpacity(0.12),
        ),
        elevation: MaterialStateProperty.all(0),
        shadowColor: MaterialStateProperty.all(Colors.transparent),
        surfaceTintColor: MaterialStateProperty.all(Colors.transparent),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.runningTotal,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    AppConfig.money(_total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: solidButtonStyle(
                        background: AppColors.espresso,
                        disabledBackground: AppColors.latte,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(t.orderMore),
                      onPressed: canOrderMore ? _orderMore : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: solidButtonStyle(
                        background: AppColors.coffee,
                        disabledBackground: AppColors.latte,
                      ),
                      icon: _requestingCheck
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.receipt_long, size: 18),
                      label: Text(
                        isCheck ? 'Check requested' : t.requestCheck,
                      ),
                      onPressed: isCheck || _requestingCheck || !canOrderMore
                          ? null
                          : _requestCheck,
                    ),
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

class _RoundBlock extends StatelessWidget {
  final OrderWithItems round;
  const _RoundBlock({required this.round});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.espresso,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ROUND ${round.order.roundNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
          const SizedBox(height: 12),
          ...round.items.map(
            (it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${it.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.espresso,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      AppConfig.money(it.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Round total',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  AppConfig.money(round.subtotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.espresso,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
