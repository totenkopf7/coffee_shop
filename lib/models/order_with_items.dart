import 'order.dart';
import 'order_item.dart';

class OrderWithItems {
  final Order order;
  final List<OrderItem> items;

  const OrderWithItems({required this.order, required this.items});

  double get subtotal =>
      items.fold(0.0, (sum, i) => sum + i.totalPrice);

  int get itemCount =>
      items.fold(0, (sum, i) => sum + i.quantity);

  @override
  String toString() =>
      'OrderWithItems(round=${order.roundNumber}, items=${items.length})';
}