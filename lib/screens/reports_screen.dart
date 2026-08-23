// screens/reports_screen.dart
import 'package:coffee_shop/screens/report_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../widgets/background_widget.dart';
import '../widgets/loading_widget.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;
  final SupabaseService _service = SupabaseService();
  String _selectedPeriod = 'daily'; // daily, weekly, monthly
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;
      String periodLabel;

      switch (_selectedPeriod) {
        case 'daily':
          startDate = DateTime(now.year, now.month, now.day);
          periodLabel = DateFormat('MMM d, yyyy').format(now);
          break;
        case 'weekly':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          periodLabel =
              '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(now)}';
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          periodLabel = DateFormat('MMMM yyyy').format(now);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          periodLabel = DateFormat('MMM d, yyyy').format(now);
      }

      final allOrders = await _service.getAllOrders();
      final filteredOrders = allOrders.where((orderData) {
        final order = Order.fromMap(orderData);
        if (order.createdAt == null) return false;
        return order.createdAt!.isAfter(startDate) ||
            order.createdAt!.isAtSameMomentAs(startDate);
      }).toList();

      // Process orders
      final processedOrders = <Map<String, dynamic>>[];
      double totalRevenue = 0;
      final productSales = <String, int>{};

      for (var orderData in filteredOrders) {
        final order = Order.fromMap(orderData);
        final table = CoffeeTable.fromMap(orderData['tables']);
        final items = await _service.getOrderItems(order.id);

        // Calculate product sales
        for (var item in items) {
          final product = await _service.getProductById(item.productId);
          final productName = product?.name ?? 'Product ${item.productId}';
          productSales[productName] =
              (productSales[productName] ?? 0) + item.quantity;
        }

        if (order.status == 'closed') {
          totalRevenue += order.total;
        }

        processedOrders.add({
          'order': order,
          'table': table,
          'items': items,
        });
      }

      // Find top product
      String? topProduct;
      int topCount = 0;
      productSales.forEach((name, count) {
        if (count > topCount) {
          topCount = count;
          topProduct = name;
        }
      });

      setState(() {
        _stats = {
          'totalOrders': filteredOrders.length,
          'closedOrders': filteredOrders
              .where((o) => Order.fromMap(o).status == 'closed')
              .length,
          'totalRevenue': totalRevenue,
          'averageOrder': filteredOrders.isNotEmpty
              ? totalRevenue / filteredOrders.length
              : 0,
          'topProduct': topProduct,
          'topProductCount': topCount,
          'orders': processedOrders,
          'periodLabel': periodLabel,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load stats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPDF() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      await PdfService.generateReport(
        title: '${_selectedPeriod.toUpperCase()} Report',
        period: _stats['periodLabel'] ?? '',
        orders: _stats['orders'] ?? [],
        totalRevenue: _stats['totalRevenue'] ?? 0,
        totalOrders: _stats['closedOrders'] ?? 0,
        summary: {
          'topProduct': _stats['topProduct'],
          'topProductCount': _stats['topProductCount'],
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to export PDF: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('📊 Reports'),
          backgroundColor: Colors.brown[800]?.withOpacity(0.92),
          foregroundColor: Colors.white,
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isExporting ? null : _exportPDF,
              tooltip: 'Export as PDF',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStats,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading statistics...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Period selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Period:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('Daily')),
                    ButtonSegment(value: 'weekly', label: Text('Weekly')),
                    ButtonSegment(value: 'monthly', label: Text('Monthly')),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedPeriod = selection.first;
                    });
                    _loadStats();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.brown[700]!;
                        }
                        return Colors.grey[200]!;
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.black87;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Period label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _stats['periodLabel'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Stats grid - now tappable
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildTappableStatCard(
                title: 'Total Orders',
                value: '${_stats['totalOrders']}',
                icon: Icons.receipt_long,
                color: Colors.blue,
                subtitle: 'All orders in period',
                onTap: () => _navigateToDetail(
                  'All Orders',
                  _stats['orders'] ?? [],
                ),
              ),
              _buildTappableStatCard(
                title: 'Completed Orders',
                value: '${_stats['closedOrders']}',
                icon: Icons.check_circle,
                color: Colors.green,
                subtitle: 'Closed orders',
                onTap: () {
                  final closedOrders = (_stats['orders'] ?? [])
                      .where((o) => (o['order'] as Order).status == 'closed')
                      .toList();
                  _navigateToDetail('Completed Orders', closedOrders);
                },
              ),
              _buildTappableStatCard(
                title: 'Total Revenue',
                value:
                    '\$${(_stats['totalRevenue'] as double).toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.orange,
                subtitle: 'From closed orders',
                onTap: () => _navigateToDetail(
                  'Revenue Details',
                  (_stats['orders'] ?? [])
                      .where((o) => (o['order'] as Order).status == 'closed')
                      .toList(),
                ),
              ),
              _buildTappableStatCard(
                title: 'Average Order',
                value:
                    '\$${(_stats['averageOrder'] as double).toStringAsFixed(2)}',
                icon: Icons.trending_up,
                color: Colors.purple,
                subtitle: 'Per order average',
                onTap: () => _navigateToDetail(
                  'Average Order Details',
                  _stats['orders'] ?? [],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTappableStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to view',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward, size: 10, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(String title, List<Map<String, dynamic>> orders) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(
          title: title,
          orders: orders,
          totalRevenue: _stats['totalRevenue'] ?? 0,
          totalOrders: _stats['closedOrders'] ?? 0,
          summary: {
            'topProduct': _stats['topProduct'],
            'topProductCount': _stats['topProductCount'],
          },
        ),
      ),
    );
  }
}
