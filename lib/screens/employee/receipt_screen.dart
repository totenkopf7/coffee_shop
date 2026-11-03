// // screens\employee\receipt_screen.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// import '../../core/app_colors.dart';
// import '../../models/coffee_table.dart';
// import '../../models/order_with_items.dart';

// class ReceiptScreen extends StatelessWidget {
//   final CoffeeTable table;
//   final List<OrderWithItems> rounds;

//   const ReceiptScreen({
//     super.key,
//     required this.table,
//     required this.rounds,
//   });

//   double get _total => rounds.fold(0.0, (s, r) => s + r.order.total);

//   /// Standard 58 mm thermal receipt page.
//   ///
//   /// - 164 pt ≈ 58 mm — nominal roll width.
//   /// - 842 pt = A4 height, which acts as the maximum length of one
//   ///   receipt. The thermal printer cuts per page, so a longer receipt
//   ///   simply produces more pages, each with zero outer margins.
//   ///
//   /// If you prefer 80 mm roll, swap to `PdfPageFormat.roll80`.
//   static const PdfPageFormat _receiptFormat = PdfPageFormat(
//     164, // ~58 mm
//     842, // tall enough for any single visit
//     marginAll: 0, // no page margins whatsoever
//   );

//   Future<void> _printReceipt() async {
//     final doc = pw.Document();
//     final now = DateTime.now();
//     final dateStr = DateFormat('MMM d, y • h:mm a').format(now);

//     doc.addPage(
//       pw.Page(
//         pageFormat: _receiptFormat,
//         // Zero page margin AND zero internal padding.
//         margin: pw.EdgeInsets.zero,
//         build: (ctx) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//             mainAxisSize: pw.MainAxisSize.min,
//             children: [
//               pw.Center(
//                 child: pw.Text(
//                   'COFFEE SHOP',
//                   style: pw.TextStyle(
//                     fontSize: 12,
//                     fontWeight: pw.FontWeight.bold,
//                     letterSpacing: 1.5,
//                   ),
//                 ),
//               ),
//               pw.SizedBox(height: 2),
//               pw.Center(
//                 child: pw.Text(
//                   'Thank you for your visit',
//                   style: const pw.TextStyle(fontSize: 7),
//                 ),
//               ),
//               pw.SizedBox(height: 4),
//               pw.Divider(height: 0.5, thickness: 0.5),
//               _kv('Table', '${table.tableNumber}'),
//               _kv('Date', dateStr),
//               pw.Divider(height: 0.5, thickness: 0.5),
//               ...rounds.expand((r) => [
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.only(top: 2, bottom: 1),
//                       child: pw.Text(
//                         'ROUND ${r.order.roundNumber}',
//                         style: pw.TextStyle(
//                           fontSize: 7,
//                           fontWeight: pw.FontWeight.bold,
//                           letterSpacing: 0.8,
//                         ),
//                       ),
//                     ),
//                     ...r.items.map(
//                       (it) => pw.Padding(
//                         padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
//                         child: pw.Row(
//                           children: [
//                             pw.SizedBox(
//                               width: 18,
//                               child: pw.Text(
//                                 '${it.quantity}x',
//                                 style: const pw.TextStyle(fontSize: 8),
//                               ),
//                             ),
//                             pw.Expanded(
//                               child: pw.Text(
//                                 it.displayName,
//                                 style: const pw.TextStyle(fontSize: 8),
//                               ),
//                             ),
//                             pw.Text(
//                               '\$${it.totalPrice.toStringAsFixed(2)}',
//                               style: const pw.TextStyle(fontSize: 8),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     pw.SizedBox(height: 2),
//                   ]),
//               pw.Divider(height: 0.5, thickness: 0.5),
//               pw.SizedBox(height: 2),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text(
//                     'TOTAL',
//                     style: pw.TextStyle(
//                       fontSize: 10,
//                       fontWeight: pw.FontWeight.bold,
//                       letterSpacing: 1,
//                     ),
//                   ),
//                   pw.Text(
//                     '\$${_total.toStringAsFixed(2)}',
//                     style: pw.TextStyle(
//                       fontSize: 12,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 6),
//               pw.Center(
//                 child: pw.Text(
//                   'Have a great day!',
//                   style: const pw.TextStyle(fontSize: 7),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (format) async => doc.save(),
//       name:
//           'receipt_table_${table.tableNumber}_${now.millisecondsSinceEpoch}.pdf',
//     );
//   }

//   pw.Widget _kv(String k, String v) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text(k, style: const pw.TextStyle(fontSize: 8)),
//           pw.Text(
//             v,
//             style: pw.TextStyle(
//               fontSize: 8,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();

//     return Scaffold(
//       backgroundColor: AppColors.cream,
//       appBar: AppBar(
//         title: const Text('Receipt'),
//         actions: [
//           IconButton(
//             tooltip: 'Print / Save PDF',
//             icon: const Icon(Icons.print),
//             onPressed: _printReceipt,
//           ),
//         ],
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Container(
//             constraints: const BoxConstraints(maxWidth: 420),
//             padding: const EdgeInsets.all(22),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 14,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const Center(child: Text('☕', style: TextStyle(fontSize: 40))),
//                 const SizedBox(height: 4),
//                 const Center(
//                   child: Text(
//                     'COFFEE SHOP',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w800,
//                       letterSpacing: 3,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 const Center(
//                   child: Text(
//                     'Thank you for your visit',
//                     style: TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 const Divider(),
//                 const SizedBox(height: 8),
//                 _row('Table', '${table.tableNumber}'),
//                 _row('Date', DateFormat('MMM d, y • h:mm a').format(now)),
//                 const SizedBox(height: 8),
//                 const Divider(),
//                 const SizedBox(height: 10),
//                 ...rounds.expand((r) => [
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 6),
//                         child: Text(
//                           'ROUND ${r.order.roundNumber}',
//                           style: const TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 1,
//                             color: AppColors.textSecondary,
//                           ),
//                         ),
//                       ),
//                       ...r.items.map((it) => Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 3),
//                             child: Row(
//                               children: [
//                                 SizedBox(
//                                   width: 34,
//                                   child: Text(
//                                     '${it.quantity}×',
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.w600),
//                                   ),
//                                 ),
//                                 Expanded(child: Text(it.displayName)),
//                                 Text(
//                                   '\$${it.totalPrice.toStringAsFixed(2)}',
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.w600),
//                                 ),
//                               ],
//                             ),
//                           )),
//                       const SizedBox(height: 8),
//                     ]),
//                 const Divider(),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('TOTAL',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w800,
//                           letterSpacing: 1,
//                         )),
//                     Text(
//                       '\$${_total.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.espresso,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.espresso,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     icon: const Icon(Icons.print),
//                     label: const Text(
//                       'Print / Save PDF',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 15,
//                       ),
//                     ),
//                     onPressed: _printReceipt,
//                   ),
//                 ),
//                 const SizedBox(height: 14),
//                 const Center(
//                   child: Text(
//                     'Have a great day! ☕',
//                     style: TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _row(String k, String v) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(k, style: const TextStyle(color: AppColors.textSecondary)),
//           Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }
// }

// screens\employee\receipt_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../models/coffee_table.dart';
import '../../models/order_with_items.dart';

class ReceiptScreen extends StatelessWidget {
  final CoffeeTable table;
  final List<OrderWithItems> rounds;

  const ReceiptScreen({
    super.key,
    required this.table,
    required this.rounds,
  });

  double get _total => rounds.fold(0.0, (s, r) => s + r.order.total);

  static const _kPrinterKey = 'receipt_printer_url';

  /// 58mm thermal receipt page. Zero margins.
  static const PdfPageFormat _receiptFormat = PdfPageFormat(
    164, // ~58mm
    842, // tall enough
    marginAll: 0,
  );

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMM d, y • h:mm a').format(now);

    doc.addPage(
      pw.Page(
        pageFormat: _receiptFormat,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(
                child: pw.Text(
                  'COFFEE SHOP',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Thank you for your visit',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(height: 0.5, thickness: 0.5),
              _kv('Table', '${table.tableNumber}'),
              _kv('Date', dateStr),
              pw.Divider(height: 0.5, thickness: 0.5),
              ...rounds.expand((r) => [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2, bottom: 1),
                      child: pw.Text(
                        'ROUND ${r.order.roundNumber}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    ...r.items.map(
                      (it) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 18,
                              child: pw.Text(
                                '${it.quantity}x',
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                it.displayName,
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                            pw.Text(
                              '\$${it.totalPrice.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                  ]),
              pw.Divider(height: 0.5, thickness: 0.5),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Have a great day!',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            v,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterUrl = prefs.getString(_kPrinterKey);

    if (savedPrinterUrl != null) {
      // Direct print to the cashier's thermal printer — no dialog, no A4.
      try {
        final pdfBytes = await _buildPdf();
        await Printing.directPrintPdf(
          printer: Printer(url: savedPrinterUrl),
          onLayout: (_) async => pdfBytes,
          name: 'receipt_table_${table.tableNumber}',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sent to receipt printer.')),
          );
        }
        return;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Direct print failed: $e')),
          );
        }
        // Fall through to the dialog so the cashier isn't stuck.
      }
    }

    // No printer saved yet, or direct print failed: show the dialog so the
    // cashier can pick the thermal printer and we remember the choice.
    await _pickPrinterAndPrint(context);
  }

  Future<void> _pickPrinterAndPrint(BuildContext context) async {
    final printers = await Printing.listPrinters();
    if (!context.mounted) return;

    if (printers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No printers found.')),
      );
      return;
    }

    final selected = await showDialog<Printer>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Select receipt printer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: printers.length,
            itemBuilder: (_, i) {
              final p = printers[i];
              return ListTile(
                leading: const Icon(Icons.print),
                title: Text(p.name),
                subtitle: Text(p.url),
                onTap: () => Navigator.pop(ctx, p),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected == null || !context.mounted) return;

    // Remember this printer for next time.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrinterKey, selected.url);

    // Print directly to it.
    try {
      final pdfBytes = await _buildPdf();
      await Printing.directPrintPdf(
        printer: selected,
        onLayout: (_) async => pdfBytes,
        name: 'receipt_table_${table.tableNumber}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Saved "${selected.name}" as receipt printer.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('☕', style: TextStyle(fontSize: 40))),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'COFFEE SHOP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Thank you for your visit',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _row('Table', '${table.tableNumber}'),
                _row('Date', DateFormat('MMM d, y • h:mm a').format(now)),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 10),
                ...rounds.expand((r) => [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'ROUND ${r.order.roundNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...r.items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    '${it.quantity}×',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(child: Text(it.displayName)),
                                Text(
                                  '\$${it.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                    ]),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        )),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text(
                      'Print Receipt',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () => _printReceipt(context),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Have a great day! ☕',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: AppColors.textSecondary)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
