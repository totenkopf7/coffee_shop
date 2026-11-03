// screens\customer\cart_sheet.dart
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';

/// Self-contained cart editor.
///
/// The PARENT is responsible for giving this widget an explicit height
/// (typically `MediaQuery.of(context).size.height * 0.9` inside a
/// `showModalBottomSheet(isScrollControlled: true)`). This widget then
/// uses a [Column] with [Expanded] in the middle and a fixed bottom bar,
/// which is the only layout that guarantees the "Place Order" button is
/// always visible regardless of viewport size.
class CartSheet extends StatefulWidget {
  final List<CartItem> initialCart;
  final void Function(List<CartItem>) onCartChanged;
  final Future<void> Function() onCheckout;

  const CartSheet({
    super.key,
    required this.initialCart,
    required this.onCartChanged,
    required this.onCheckout,
  });

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  late List<CartItem> _cart;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _cart = widget.initialCart
        .map((c) => CartItem(product: c.product, quantity: c.quantity))
        .toList();
  }

  double get _total => _cart.fold(0.0, (s, c) => s + c.total);
  int get _count => _cart.fold(0, (s, c) => s + c.quantity);

  void _increment(Product p) {
    setState(() {
      try {
        _cart.firstWhere((c) => c.product.id == p.id).quantity++;
      } catch (_) {
        _cart.add(CartItem(product: p));
      }
    });
    widget.onCartChanged(_cart);
  }

  void _decrement(Product p) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.product.id == p.id);
      if (idx == -1) return;
      _cart[idx].quantity--;
      if (_cart[idx].quantity <= 0) _cart.removeAt(idx);
    });
    widget.onCartChanged(_cart);
  }

  Future<void> _handleCheckout() async {
    if (_cart.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onCheckout();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.foam,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          // IMPORTANT: this Column is inside a SizedBox with an explicit
          // height (set by the caller). It must NOT be `min` — it must
          // take the full height so Expanded can hand the middle slot a
          // real pixel budget. The bottom bar then sits at the very
          // bottom of that budget, always visible.
          children: [
            // ── Handle ────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  const Text(
                    'Your Order',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.espresso,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_count item${_count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: AppColors.espresso),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Scrollable list ──────────────────────────────────────
            Expanded(
              child: _cart.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Your cart is empty',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _cart.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _CartRow(
                        item: _cart[i],
                        onIncrement: () => _increment(_cart[i].product),
                        onDecrement: () => _decrement(_cart[i].product),
                      ),
                    ),
            ),

            // ── Bottom bar (Place Order) ──────────────────────────────
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.espresso,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  disabledBackgroundColor: AppColors.latte,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed:
                    _cart.isEmpty || _submitting ? null : _handleCheckout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _image(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.espresso,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${item.product.price.toStringAsFixed(2)} each',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, size: 18),
                  color: AppColors.coffee,
                  onPressed: onDecrement,
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 18),
                  color: AppColors.coffee,
                  onPressed: onIncrement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _image() {
    final url = item.product.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.cream,
        child: const Icon(Icons.local_cafe, color: AppColors.latte),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.cream,
        child: const Icon(Icons.local_cafe, color: AppColors.latte),
      ),
    );
  }
}
