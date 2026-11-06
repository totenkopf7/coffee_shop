// screens/customer/customer_menu_screen.dart
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../core/config.dart';
import '../../models/cart_item.dart';
import '../../models/coffee_table.dart';
import '../../models/product.dart';
import '../../models/table_session.dart';
import '../../services/cart_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/money_text.dart';
import 'cart_sheet.dart';
import 'order_status_screen.dart';

class CustomerMenuScreen extends StatefulWidget {
  final CoffeeTable table;
  final TableSession session;

  const CustomerMenuScreen({
    super.key,
    required this.table,
    required this.session,
  });

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final _service = SupabaseService.instance;
  final _cartService = CartService.instance;

  bool _loading = true;
  String? _error;
  List<Product> _products = [];
  List<CartItem> _cart = [];
  String _selectedCategory = 'All';
  TableSession? _liveSession;
  bool _placingOrder = false;
  bool _requestingCheck = false;

  bool _cartDirty = false;
  Future<void>? _persistInFlight;

  @override
  void initState() {
    super.initState();
    _liveSession = widget.session;
    _load();
    _restoreCart();
    _watchSession();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _service.getAvailableProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load menu: $e';
        _loading = false;
      });
    }
  }

  Future<void> _restoreCart() async {
    final saved = await _cartService.load(widget.session.id);
    if (!mounted) return;
    if (!_cartDirty) {
      setState(() => _cart = saved);
    }
  }

  void _persistCart() {
    final previous = _persistInFlight ?? Future<void>.value();
    final next = previous.catchError((_) {}).then((_) {
      return _cartService.save(widget.session.id, _cart);
    });
    _persistInFlight = next;
    next.catchError((e) => debugPrint('persistCart error: $e'));
  }

  void _watchSession() {
    _service.watchSession(widget.session.id).listen(
      (s) {
        if (!mounted) return;
        if (s == null) return;
        setState(() => _liveSession = s);
      },
      onError: (e) => debugPrint('watchSession error: $e'),
    );
  }

  List<String> get _categories {
    final set = <String>{'All'};
    for (final p in _products) {
      if (p.category != null && p.category!.trim().isNotEmpty) {
        set.add(p.category!.trim());
      }
    }
    final list = set.toList();
    list.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  List<Product> get _filtered {
    if (_selectedCategory == 'All') return _products;
    return _products
        .where((p) => (p.category ?? '').trim() == _selectedCategory)
        .toList();
  }

  int _qtyFor(int productId) {
    for (final c in _cart) {
      if (c.product.id == productId) return c.quantity;
    }
    return 0;
  }

  void _replaceCart(List<CartItem> next) {
    _cartDirty = true;
    setState(() {
      _cart = List<CartItem>.from(next);
    });
    _persistCart();
  }

  void _add(Product p) {
    final next = _cart
        .map((c) => CartItem(product: c.product, quantity: c.quantity))
        .toList();
    CartItem? existing;
    for (final c in next) {
      if (c.product.id == p.id) {
        existing = c;
        break;
      }
    }
    if (existing != null) {
      existing.quantity++;
    } else {
      next.add(CartItem(product: p));
    }
    _replaceCart(next);
  }

  void _remove(Product p) {
    final next = _cart
        .map((c) => CartItem(product: c.product, quantity: c.quantity))
        .toList();
    final idx = next.indexWhere((c) => c.product.id == p.id);
    if (idx == -1) return;
    next[idx].quantity--;
    if (next[idx].quantity <= 0) next.removeAt(idx);
    _replaceCart(next);
  }

  double get _cartTotal => _cart.fold<double>(0, (s, c) => s + c.total);
  int get _cartCount => _cart.fold<int>(0, (s, c) => s + c.quantity);

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openCart() async {
    if (_cart.isEmpty) {
      _showSnack(AppLocalizations.t(context).cartEmptyAddFirst);
      return;
    }

    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.9;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SizedBox(
        height: sheetHeight,
        child: CartSheet(
          initialCart: List<CartItem>.from(_cart),
          sessionId: widget.session.id,
          onCartChanged: (next) {
            _cartDirty = true;
            _cart = List<CartItem>.from(next);
            _persistCart();
          },
          onCheckout: () async {
            await _placeOrderFromSheet(sheetContext);
          },
          onCheckRequested: () async {
            final s = await _service.getSessionById(widget.session.id);
            if (!mounted) return;
            if (s != null) setState(() => _liveSession = s);
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _placeOrderFromSheet(BuildContext sheetContext) async {
    if (_cart.isEmpty || _placingOrder) return;
    _placingOrder = true;

    final items = _cart
        .map((c) => {
              'productId': c.product.id,
              'quantity': c.quantity,
              'unitPrice': c.product.price,
            })
        .toList();

    Navigator.of(sheetContext).pop();
    if (mounted) setState(() {});

    try {
      final order = await _service.placeOrder(
        sessionId: widget.session.id,
        tableId: widget.table.id,
        items: items,
      );

      await _cartService.clear(widget.session.id);
      if (!mounted) return;
      setState(() {
        _cart = [];
        _placingOrder = false;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(
            table: widget.table,
            session: _liveSession ?? widget.session,
            placedOrderId: order.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      _showSnack('Failed to place order: $e');
    }
  }

  Future<void> _openStatus() async {
    final s = _liveSession;
    if (s == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(
          table: widget.table,
          session: s,
        ),
      ),
    );
  }

  Future<void> _requestCheck() async {
    final s = _liveSession;
    if (s == null) return;
    if (!s.isOpen) {
      _showSnack('The check has already been requested.');
      return;
    }
    if (_requestingCheck) return;

    final t = AppLocalizations.t(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
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
                borderRadius: BorderRadius.circular(14),
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
      _showSnack(t.checkRequestedSnack);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to request check: $e');
    } finally {
      if (mounted) setState(() => _requestingCheck = false);
    }
  }

  void _viewImage(Product product) {
    final url = product.imageUrl;
    if (url == null || url.trim().isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.92),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _ImageViewerScreen(product: product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.t(context);
    final isCheck = _liveSession?.isCheckRequested ?? false;
    final showCartBar = _cartCount > 0 && !_placingOrder;
    final showBottomActions = showCartBar || !isCheck;

    return Scaffold(
      backgroundColor: const Color(0xFFF2E8DC),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroHeader(t, isCheck),
            if (isCheck) _buildCheckRequestedBanner(t),
            if (_placingOrder)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.caramel,
                  backgroundColor: Color(0xFFF2E8DC),
                ),
              ),
            if (_loading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingWidget(message: t.loadBrewing),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load menu',
                  subtitle: _error,
                  action: ElevatedButton(
                    onPressed: _load,
                    child: Text(t.retry),
                  ),
                ),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.local_cafe,
                  title: t.menuIsEmpty,
                  subtitle: t.menuIsEmptyHint,
                ),
              )
            else ...[
              SliverToBoxAdapter(child: _buildCategoryChips(t)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  showBottomActions ? 160 : 24,
                ),
                sliver: SliverList.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final p = _filtered[i];
                    return _MenuCard(
                      product: p,
                      quantity: _qtyFor(p.id),
                      onAdd: () => _add(p),
                      onRemove: () => _remove(p),
                      onImageTap: () => _viewImage(p),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: showBottomActions
          ? _buildBottomActions(t, showCartBar, isCheck)
          : null,
    );
  }

  Widget _buildHeroHeader(AppLocalizations t, bool isCheck) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: AppColors.espresso,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: t.yourOrder,
          icon: const Icon(Icons.receipt_long),
          onPressed: _openStatus,
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tablePill(widget.table.tableNumber),
            if (isCheck) ...[
              const SizedBox(width: 8),
              _checkPill(t),
            ],
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3E2723),
                Color(0xFF5D4037),
                Color(0xFF8D6E63),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -60,
                bottom: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.caramel.withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE7C9A9).withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // ── Centered, top-aligned header content ─────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 56),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E9D7).withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF5E9D7).withOpacity(0.35),
                            width: 1.4,
                          ),
                        ),
                        child: const Text('☕', style: TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.ourMenu,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF5E9D7),
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.menuTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFF5E9D7).withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tablePill(int number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_restaurant, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Table $number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkPill(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_active, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            t.checkBadge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRequestedBanner(AppLocalizations t) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        color: AppColors.dangerLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.notifications_active,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.checkRequestedBanner,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AppLocalizations t) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = _categories[i];
          final sel = c == _selectedCategory;
          final label = c == 'All' ? t.all : c;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: sel ? AppColors.espresso : const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: sel ? AppColors.espresso : const Color(0xFFE5D5C0),
                width: 1.4,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: AppColors.espresso.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => setState(() => _selectedCategory = c),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sel) ...[
                        const Icon(Icons.circle,
                            size: 6, color: AppColors.caramel),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: sel
                              ? const Color(0xFFF5E9D7)
                              : AppColors.espresso,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions(
      AppLocalizations t, bool showCartBar, bool isCheck) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: 10 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E8DC),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCartBar)
            SizedBox(
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.transparent,
                ),
                onPressed: _placingOrder ? null : _openCart,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.caramel,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t.viewCart,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    MoneyText(
                      _cartTotal,
                      style: const TextStyle(
                        color: Color(0xFFF5E9D7),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showCartBar && !isCheck) const SizedBox(height: 10),
          if (!isCheck)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.espresso,
                  side: const BorderSide(color: AppColors.espresso, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: const Color(0xFFFFFDF9),
                ),
                icon: _requestingCheck
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.espresso,
                        ),
                      )
                    : const Icon(Icons.receipt_long, size: 18),
                label: Text(
                  t.requestCheck,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                onPressed: _requestingCheck ? null : _requestCheck,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Menu card
// ═══════════════════════════════════════════════════════════════════════
class _MenuCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onImageTap;

  const _MenuCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.t(context);
    final hasCategory =
        product.category != null && product.category!.trim().isNotEmpty;
    final hasImage =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: hasImage ? onImageTap : null,
              behavior: HitTestBehavior.opaque,
              child: _imageTile(hasImage),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCategory)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E9D7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          product.category!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.coffee,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.espresso,
                      height: 1.2,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (product.description != null &&
                      product.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _priceTag(),
                      const Spacer(),
                      _stepper(t),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageTile(bool hasImage) {
    const size = 108.0;
    final url = product.imageUrl;

    Widget child;
    if (!hasImage || url == null || url.isEmpty) {
      child = Container(
        color: const Color(0xFFF5E9D7),
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_cafe,
          color: AppColors.caramel,
          size: 42,
        ),
      );
    } else {
      child = Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, c, progress) {
              if (progress == null) return c;
              return Container(
                color: const Color(0xFFF5E9D7),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.caramel,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF5E9D7),
              alignment: Alignment.center,
              child: const Icon(Icons.local_cafe,
                  color: AppColors.caramel, size: 42),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.zoom_out_map,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(width: size, height: size, child: child),
      ),
    );
  }

  Widget _priceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9D7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7D3B5), width: 1),
      ),
      child: MoneyText(
        product.price,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.espresso,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _stepper(AppLocalizations t) {
    if (quantity == 0) {
      return Material(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  t.add,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9D7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7D3B5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(icon: Icons.remove, onTap: onRemove),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 26),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.espresso,
              ),
            ),
          ),
          _stepperButton(icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.espresso),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Full-screen image viewer
// ═══════════════════════════════════════════════════════════════════════
class _ImageViewerScreen extends StatelessWidget {
  final Product product;
  const _ImageViewerScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl ?? '';
    final t = AppLocalizations.t(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(color: Colors.black.withOpacity(0.92)),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 64, 16, 120),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Hero(
                      tag: 'product_image_${product.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, c, progress) {
                            if (progress == null) return c;
                            return const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(Icons.broken_image,
                                color: Colors.white54, size: 72),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: t.cancel,
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    MoneyText(
                      product.price,
                      style: const TextStyle(
                        color: Color(0xFFF5E9D7),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (product.description != null &&
                        product.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        product.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
