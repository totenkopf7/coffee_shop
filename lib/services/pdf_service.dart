// services/pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/coffee_table.dart';

class PdfService {
  static const int maxOrdersPerPage = 20;

  static Future<pw.Font> _loadFont() async {
    try {
      final fontData =
          await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
      return pw.Font.ttf(fontData.buffer.asByteData());
    } catch (e) {
      print('⚠️ Custom font not found, using fallback');
      return pw.Font.helvetica();
    }
  }

  static Future<void> generateReport({
    required String title,
    required String period,
    required List<Map<String, dynamic>> orders,
    required double totalRevenue,
    required int totalOrders,
    required Map<String, dynamic> summary,
  }) async {
    try {
      final pdf = pw.Document();
      final font = await _loadFont();

      // Filter out null orders
      final validOrders = orders.where((order) {
        try {
          return order['order'] != null && order['table'] != null;
        } catch (e) {
          return false;
        }
      }).toList();

      // Calculate analytics
      final analytics = _calculateAnalytics(validOrders);

      if (validOrders.isEmpty) {
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(title, period, font),
                _buildSummary(analytics, font),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'No orders found for this period',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 16,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                _buildFooter(context, font),
              ],
            ),
          ),
        );
      } else if (validOrders.length > maxOrdersPerPage) {
        // First page with analytics
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(title, period, font),
                _buildSummary(analytics, font),
                _buildTopProducts(analytics, font),
                _buildTablePerformance(analytics, font),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Showing first ${maxOrdersPerPage} of ${validOrders.length} orders',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                _buildOrdersTable(
                    validOrders.sublist(0, maxOrdersPerPage), font),
                _buildFooter(context, font),
              ],
            ),
          ),
        );

        // Additional pages for orders only
        int pageNumber = 2;
        for (int i = maxOrdersPerPage;
            i < validOrders.length;
            i += maxOrdersPerPage) {
          final end = (i + maxOrdersPerPage < validOrders.length)
              ? i + maxOrdersPerPage
              : validOrders.length;
          final pageOrders = validOrders.sublist(i, end);

          pdf.addPage(
            pw.Page(
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader('$title (Page $pageNumber)', period, font),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Orders ${i + 1} - $end of ${validOrders.length}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  _buildOrdersTable(pageOrders, font),
                  _buildFooter(context, font),
                ],
              ),
            ),
          );
          pageNumber++;
        }
      } else {
        // Single page with all analytics
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(title, period, font),
                _buildSummary(analytics, font),
                _buildTopProducts(analytics, font),
                _buildTablePerformance(analytics, font),
                _buildOrdersTable(validOrders, font),
                _buildFooter(context, font),
              ],
            ),
          ),
        );
      }

      final bytes = await pdf.save();

      try {
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${title.toLowerCase().replaceAll(' ', '_')}_$period.pdf',
        );
      } catch (e) {
        print('⚠️ sharePdf failed, trying layoutPdf: $e');
        try {
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => bytes,
          );
        } catch (e2) {
          print('⚠️ layoutPdf failed: $e2');
          rethrow;
        }
      }
    } catch (e) {
      print('❌ PDF Generation Error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _calculateAnalytics(
      List<Map<String, dynamic>> orders) {
    double totalRevenue = 0;
    int totalItems = 0;
    final productSales = <String, int>{};
    final productRevenue = <String, double>{};
    final tableOrders = <int, int>{};
    final tableRevenue = <int, double>{};
    int totalOrders = 0;
    int closedOrders = 0;

    for (var orderData in orders) {
      try {
        final order = orderData['order'] as Order?;
        final table = orderData['table'] as CoffeeTable?;
        final items = orderData['items'] as List<OrderItem>? ?? [];

        if (order == null || table == null) continue;

        totalOrders++;
        if (order.status == 'closed') {
          closedOrders++;
          totalRevenue += order.total;
        }

        // Track table performance
        tableOrders[table.tableNumber] =
            (tableOrders[table.tableNumber] ?? 0) + 1;
        if (order.status == 'closed') {
          tableRevenue[table.tableNumber] =
              (tableRevenue[table.tableNumber] ?? 0) + order.total;
        }

        // Track product sales
        for (var item in items) {
          final productName = item.product?.name ?? 'Product ${item.productId}';
          totalItems += item.quantity;
          productSales[productName] =
              (productSales[productName] ?? 0) + item.quantity;
          productRevenue[productName] = (productRevenue[productName] ?? 0) +
              (item.unitPrice * item.quantity);
        }
      } catch (e) {
        continue;
      }
    }

    // Sort products by sales
    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort tables by revenue
    final sortedTables = tableRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'closedOrders': closedOrders,
      'totalItems': totalItems,
      'uniqueProducts': productSales.length,
      'topProducts': sortedProducts.take(5).toList(),
      'topTables': sortedTables.take(5).toList(),
      'avgOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      'avgItemsPerOrder': totalOrders > 0 ? totalItems / totalOrders : 0,
    };
  }

  static pw.Widget _buildHeader(String title, String period, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.brown700,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '☕ Coffee Shop',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    'Management Report',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    period,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildSummary(Map<String, dynamic> analytics, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '📊 Summary',
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryCard(
                'Total Revenue',
                '\$${(analytics['totalRevenue'] as double).toStringAsFixed(2)}',
                PdfColors.green,
                font,
              ),
              _buildSummaryCard(
                'Total Orders',
                analytics['totalOrders'].toString(),
                PdfColors.blue,
                font,
              ),
              _buildSummaryCard(
                'Closed Orders',
                analytics['closedOrders'].toString(),
                PdfColors.cyan,
                font,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryCard(
                'Items Sold',
                analytics['totalItems'].toString(),
                PdfColors.purple,
                font,
              ),
              _buildSummaryCard(
                'Unique Products',
                analytics['uniqueProducts'].toString(),
                PdfColors.teal,
                font,
              ),
              _buildSummaryCard(
                'Avg Order',
                '\$${(analytics['avgOrderValue'] as double).toStringAsFixed(2)}',
                PdfColors.orange,
                font,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              '📈 ${(analytics['avgItemsPerOrder'] as double).toStringAsFixed(1)} items per order on average',
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTopProducts(
      Map<String, dynamic> analytics, pw.Font font) {
    final topProducts = analytics['topProducts'] as List<MapEntry<String, int>>;

    if (topProducts.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🏆 Top Selling Products',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...topProducts
              .map((entry) => pw.Row(
                    children: [
                      pw.Container(
                        width: 20,
                        height: 20,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.brown100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${topProducts.indexOf(entry) + 1}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.brown700,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          entry.key,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${entry.value} sold',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown700,
                        ),
                      ),
                    ],
                  ))
              .toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildTablePerformance(
      Map<String, dynamic> analytics, pw.Font font) {
    final topTables = analytics['topTables'] as List<MapEntry<int, double>>;

    if (topTables.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🪑 Top Performing Tables',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...topTables
              .map((entry) => pw.Row(
                    children: [
                      pw.Container(
                        width: 20,
                        height: 20,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${topTables.indexOf(entry) + 1}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          'Table ${entry.key}',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ))
              .toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(
    String label,
    String value,
    PdfColor color,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor(color.red, color.green, color.blue, 0.3),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOrdersTable(
    List<Map<String, dynamic>> orders,
    pw.Font font,
  ) {
    if (orders.isEmpty) {
      return pw.Column(
        children: [
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'No orders found for this period',
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        pw.Text(
          '📋 Order Details (${orders.length} orders)',
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(0.8),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(0.8),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColors.brown100,
              ),
              children: [
                _buildTableCell('Order ID', isHeader: true, font: font),
                _buildTableCell('Table', isHeader: true, font: font),
                _buildTableCell('Items', isHeader: true, font: font),
                _buildTableCell('Qty', isHeader: true, font: font),
                _buildTableCell('Status', isHeader: true, font: font),
                _buildTableCell('Total', isHeader: true, font: font),
              ],
            ),
            ...orders.map((orderData) {
              try {
                final order = orderData['order'] as Order?;
                final table = orderData['table'] as CoffeeTable?;
                final items = orderData['items'] as List<OrderItem>? ?? [];

                if (order == null || table == null) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell('Invalid', font: font),
                      _buildTableCell('-', font: font),
                      _buildTableCell('-', font: font),
                      _buildTableCell('-', font: font),
                      _buildTableCell('-', font: font),
                      _buildTableCell('-', font: font),
                    ],
                  );
                }

                final totalQty =
                    items.fold<int>(0, (sum, item) => sum + item.quantity);
                // Use real product names
                final itemNames = items
                    .map((item) =>
                        '${item.quantity}x ${item.product?.name ?? 'Product ${item.productId}'}')
                    .join('\n');

                return pw.TableRow(
                  children: [
                    _buildTableCell(
                      order.id.substring(0, 8),
                      font: font,
                    ),
                    _buildTableCell(
                      '${table.tableNumber}',
                      font: font,
                    ),
                    _buildTableCell(
                      itemNames,
                      font: font,
                    ),
                    _buildTableCell(
                      totalQty.toString(),
                      font: font,
                    ),
                    _buildTableCell(
                      order.statusDisplay,
                      font: font,
                    ),
                    _buildTableCell(
                      '\$${order.total.toStringAsFixed(2)}',
                      isTotal: true,
                      font: font,
                    ),
                  ],
                );
              } catch (e) {
                return pw.TableRow(
                  children: [
                    _buildTableCell('Error', font: font),
                    _buildTableCell('-', font: font),
                    _buildTableCell('-', font: font),
                    _buildTableCell('-', font: font),
                    _buildTableCell('-', font: font),
                    _buildTableCell('-', font: font),
                  ],
                );
              }
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isTotal = false,
    required pw.Font font,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight: isHeader
              ? pw.FontWeight.bold
              : (isTotal ? pw.FontWeight.bold : pw.FontWeight.normal),
          fontSize: isHeader ? 10 : 9,
          color: isHeader ? PdfColors.white : null,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Coffee Shop Management System',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber}',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '© ${DateTime.now().year} Coffee Shop - All Rights Reserved',
          style: pw.TextStyle(
            font: font,
            fontSize: 8,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }
}
