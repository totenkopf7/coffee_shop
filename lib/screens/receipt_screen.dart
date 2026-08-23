// import 'package:flutter/material.dart';
// import '../models/order.dart';
// import '../models/coffee_table.dart';
// import '../models/order_item.dart';

// /// Shows the receipt after closing an order
// ///
// /// This is designed to look like a real receipt and can be
// /// printed later with a thermal printer.
// class ReceiptScreen extends StatelessWidget {
//   final Map<String, dynamic> orderData;

//   const ReceiptScreen({super.key, required this.orderData});

//   @override
//   Widget build(BuildContext context) {
//     final order = orderData['order'] as Order;
//     final table = orderData['table'] as CoffeeTable;
//     final items = orderData['items'] as List<OrderItem>;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('🧾 Receipt'),
//         backgroundColor: Colors.brown[800],
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.print),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Print functionality coming soon!'),
//                   duration: Duration(seconds: 2),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Container(
//             constraints: const BoxConstraints(maxWidth: 400),
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.3),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: _buildReceiptContent(context, order, table, items),
//           ),
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Expanded(
//               child: OutlinedButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Back to Tables'),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Close all screens and return to home
//                   Navigator.popUntil(context, (route) => route.isFirst);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.brown[700],
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('🏠 Home'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReceiptContent(
//     BuildContext context,
//     Order order,
//     CoffeeTable table,
//     List<OrderItem> items,
//   ) {
//     final now = DateTime.now();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         // Header
//         Text(
//           '☕ COFFEE SHOP',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Colors.brown[800],
//             letterSpacing: 2,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Thank you for your visit!',
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.grey[600],
//             letterSpacing: 1,
//           ),
//         ),
//         const Divider(
//           height: 32,
//           thickness: 1,
//           color: Colors.grey,
//         ),

//         // Order details
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Table: ${table.tableNumber}',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             Text(
//               'Order #${order.id.substring(0, 8)}',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Date: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
//           style: TextStyle(color: Colors.grey[600]),
//         ),
//         const Divider(height: 24),

//         // Items
//         const Text(
//           'ITEMS',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         ...items.map((item) => Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: Text(
//                       item.product?.name ?? 'Product ${item.productId}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 1,
//                     child: Text(
//                       '${item.quantity}×',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 1,
//                     child: Text(
//                       '\$${item.unitPrice.toStringAsFixed(2)}',
//                       textAlign: TextAlign.right,
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//             )),

//         const Divider(height: 24),

//         // Total
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'TOTAL:',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               '\$${order.total.toStringAsFixed(2)}',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.brown[800],
//               ),
//             ),
//           ],
//         ),
//         const Divider(height: 32),

//         // Footer
//         Text(
//           'Thank you!',
//           style: TextStyle(
//             fontSize: 16,
//             color: Colors.grey[600],
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Have a great day! ☕',
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.grey[400],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           '--- ${now.toString().substring(0, 10)} ---',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[400],
//             letterSpacing: 2,
//           ),
//         ),
//       ],
//     );
//   }
// }

// WITH BACKGROUND IMAGE
// screens/receipt_screen.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/coffee_table.dart';
import '../models/order_item.dart';
import '../widgets/background_widget.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const ReceiptScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final order = orderData['order'] as Order;
    final table = orderData['table'] as CoffeeTable;
    final items = orderData['items'] as List<OrderItem>;

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('🧾 Receipt'),
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Print functionality coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildReceiptContent(context, order, table, items),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Tables'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🏠 Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptContent(
    BuildContext context,
    Order order,
    CoffeeTable table,
    List<OrderItem> items,
  ) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '☕ COFFEE SHOP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Thank you for your visit!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
        const Divider(
          height: 32,
          thickness: 1,
          color: Colors.grey,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Table: ${table.tableNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Order #${order.id.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Date: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const Divider(height: 24),
        const Text(
          'ITEMS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.product?.name ?? 'Product ${item.productId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item.quantity}×',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '\$${item.unitPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
        const Divider(height: 24),
        Row(
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
              '\$${order.total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        Text(
          'Thank you!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Have a great day! ☕',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '--- ${now.toString().substring(0, 10)} ---',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
