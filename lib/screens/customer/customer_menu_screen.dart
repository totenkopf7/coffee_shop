// screens\customer\customer_menu_screen.dart
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/cart_item.dart';
import '../../models/coffee_table.dart';
import '../../models/product.dart';
import '../../models/table_session.dart';
import '../../services/cart_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
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
      _showSnack('Your cart is empty. Add something first!');
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
          onCartChanged: (next) {
            _cartDirty = true;
            _cart = List<CartItem>.from(next);
            _persistCart();
          },
          onCheckout: () async {
            await _placeOrderFromSheet(sheetContext);
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Request the check?'),
        content: const Text(
          'A staff member will bring your bill. '
          'You can still order more until they close the table.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Request Check'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _requestingCheck = true);
    try {
      await _service.requestCheck(s.id);
      if (!mounted) return;
      _showSnack(
        'Staff notified — someone will bring your check shortly.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to request check: $e');
    } finally {
      if (mounted) setState(() => _requestingCheck = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCheck = _liveSession?.isCheckRequested ?? false;
    final showCartBar = _cartCount > 0 && !_placingOrder;
    final hasCheckButton = !isCheck;
    final showBottomActions = showCartBar || hasCheckButton;

    return Scaffold(
      backgroundColor: AppColors.foam,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(isCheck),
            if (isCheck) _buildCheckRequestedBanner(),
            if (_placingOrder)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.caramel,
                  backgroundColor: AppColors.cream,
                ),
              ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingWidget(message: 'Brewing the menu...'),
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
                    child: const Text('Retry'),
                  ),
                ),
              )
            else if (_products.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.local_cafe,
                  title: 'Menu is empty',
                  subtitle: 'The shop hasn\'t added items yet.',
                ),
              )
            else ...[
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  showBottomActions ? 140 : 24,
                ),
                sliver: SliverList.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final p = _filtered[i];
                    return _MenuCard(
                      product: p,
                      quantity: _qtyFor(p.id),
                      onAdd: () => _add(p),
                      onRemove: () => _remove(p),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar:
          showBottomActions ? _buildBottomActions(showCartBar, isCheck) : null,
    );
  }

  Widget _buildBottomActions(bool showCartBar, bool isCheck) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: 10 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCartBar)
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _placingOrder ? null : _openCart,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.caramel,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'View Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '\$${_cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showCartBar && !isCheck) const SizedBox(height: 10),
          if (!isCheck)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coffee,
                        side: const BorderSide(
                            color: AppColors.coffee, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _requestingCheck
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.coffee,
                              ),
                            )
                          : const Icon(Icons.receipt_long, size: 18),
                      label: const Text(
                        'Request check',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _requestingCheck ? null : _requestCheck,
                    ),
                  ),
                ),
                if (showCartBar) const SizedBox(width: 10),
                if (showCartBar)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.espresso,
                          side: const BorderSide(
                              color: AppColors.espresso, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text(
                          'Order more',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => _openStatus(),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isCheck) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: AppColors.espresso,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: 'Your order',
          icon: const Icon(Icons.receipt_long),
          onPressed: _openStatus,
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_restaurant,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Table ${widget.table.tableNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (isCheck) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active,
                        size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'CHECK',
                      style: TextStyle(
                        fontSize: 10,
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
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.espresso,
                AppColors.darkRoast,
                AppColors.coffee,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('☕', style: TextStyle(fontSize: 30)),
                  SizedBox(height: 10),
                  Text(
                    'Our Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Crafted with care, brewed to order.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRequestedBanner() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        color: AppColors.dangerLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.notifications_active, color: AppColors.danger, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Check requested — a staff member is on the way. '
                'You can still order more.',
                style: TextStyle(
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

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _categories[i];
          final sel = c == _selectedCategory;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: sel ? AppColors.espresso : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: sel ? AppColors.espresso : AppColors.divider,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: AppColors.espresso.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => _selectedCategory = c),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 96,
                height: 96,
                child: _image(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.category != null &&
                      product.category!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.caramel,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                      height: 1.2,
                    ),
                  ),
                  if (product.description != null &&
                      product.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.formattedPrice,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.caramel,
                          ),
                        ),
                      ),
                      _stepper(),
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

  Widget _stepper() {
    if (quantity == 0) {
      return Material(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onAdd,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(icon: Icons.remove, onTap: onRemove),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.espresso,
              ),
            ),
          ),
          _stepperButton(icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.coffee),
        ),
      ),
    );
  }

  Widget _image() {
    final url = product.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.cream,
        child: const Icon(Icons.local_cafe, color: AppColors.latte, size: 36),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.cream,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.coffee,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.cream,
        child: const Icon(Icons.local_cafe, color: AppColors.latte, size: 36),
      ),
    );
  }
}
