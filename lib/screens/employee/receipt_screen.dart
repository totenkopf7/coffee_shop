// screens/employee/receipt_screen.dart
import 'dart:typed_data';

import 'package:coffee_shop/core/config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
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

  /// POS roll: 58 mm wide, no margins. This is what every common POS
  /// printer (Epson TM-T20, Xprinter XP-58, etc.) expects.
  static const PdfPageFormat _receiptFormat = PdfPageFormat(
    164, // ~58 mm
    842, // tall enough for any single visit
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
                              AppConfig.moneyPlain(it.totalPrice),
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
                    AppConfig.moneyPlain(_total),
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

  /// Print the receipt.
  ///
  /// On WEB the only thing that works is `Printing.layoutPdf`, which opens
  /// the browser's print dialog. From there the cashier selects the POS
  /// printer. Chrome/Edge remember the choice per-session, so after the
  /// first print the POS is pre-selected.
  ///
  /// On DESKTOP we try a saved printer via `directPrintPdf` first (silent,
  /// no dialog), and fall back to `layoutPdf` if it fails.
  ///
  /// On MOBILE `layoutPdf` opens the native print sheet.
  Future<void> _printReceipt(BuildContext context) async {
    final pdfBytes = await _buildPdf();

    // ── 1) Web: always use the browser print dialog ─────────────────
    if (kIsWeb) {
      try {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'receipt_table_${table.tableNumber}',
        );
      } catch (e) {
        if (context.mounted) {
          _snack(context, 'Print failed: $e');
        }
      }
      return;
    }

    // ── 2) Desktop/mobile: try saved printer first (silent) ─────────
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_kPrinterKey);

    if (savedUrl != null && savedUrl.isNotEmpty) {
      try {
        await Printing.directPrintPdf(
          printer: Printer(url: savedUrl),
          onLayout: (_) async => pdfBytes,
          name: 'receipt_table_${table.tableNumber}',
        );
        if (context.mounted) {
          _snack(context, 'Sent to POS printer.');
        }
        return;
      } catch (_) {
        // fall through to dialog
      }
    }

    // ── 3) No saved printer, or direct print failed → dialog ────────
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'receipt_table_${table.tableNumber}',
      );
    } catch (e) {
      if (context.mounted) {
        _snack(context, 'Print failed: $e');
      }
    }
  }

  /// Desktop/mobile: let the cashier pick a printer once; remembered.
  /// Web: no-op (browser remembers the print target itself).
  Future<void> _pickPrinter(BuildContext context) async {
    if (kIsWeb) {
      _snack(
        context,
        'On web, choose the POS in the browser print dialog. '
        'Chrome remembers it after the first print.',
      );
      return;
    }

    List<Printer> printers = const [];
    try {
      printers = await Printing.listPrinters();
    } catch (_) {}

    if (!context.mounted) return;
    if (printers.isEmpty) {
      _snack(
        context,
        'No printers detected by the OS. Make sure the POS driver is '
        'installed and set as default.',
      );
      return;
    }

    final selected = await showDialog<Printer>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Select POS printer'),
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

    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrinterKey, selected.url);
    if (context.mounted) {
      _snack(context, 'Saved "${selected.name}" as POS printer.');
    }
  }

  Future<void> _clearSavedPrinter(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrinterKey);
    if (context.mounted) {
      _snack(context, 'Saved printer cleared.');
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.t(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(t.printReceipt),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Printer settings',
            icon: const Icon(Icons.print),
            onSelected: (v) {
              if (v == 'print') _printReceipt(context);
              if (v == 'pick') _pickPrinter(context);
              if (v == 'clear') _clearSavedPrinter(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'print', child: Text('Print now')),
              PopupMenuItem(value: 'pick', child: Text('Change POS printer')),
              PopupMenuItem(
                  value: 'clear', child: Text('Forget saved printer')),
            ],
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
                                  AppConfig.moneyPlain(_total),
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
                      AppConfig.money(_total),
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
                    label: Text(
                      t.printReceipt,
                      style: const TextStyle(
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
