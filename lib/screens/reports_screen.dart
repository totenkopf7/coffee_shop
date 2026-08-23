// screens/reports_screen.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/coffee_table.dart';
import '../widgets/background_widget.dart';
import '../widgets/loading_widget.dart';

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
      final totalOrders = await _service.getTotalOrdersCount();
      final todayOrders = await _service.getTodayOrdersCount();
      final totalRevenue = await _service.getTotalRevenue();

      final tables = await _service.getTables();
      final occupiedTables = tables.where((t) => t.isOccupied).length;

      setState(() {
        _stats = {
          'totalOrders': totalOrders,
          'todayOrders': todayOrders,
          'totalRevenue': totalRevenue,
          'occupiedTables': occupiedTables,
          'totalTables': tables.length,
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

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('📊 Reports'),
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStats,
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

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Total Orders',
          value: '${_stats['totalOrders']}',
          icon: Icons.receipt_long,
          color: Colors.blue,
          subtitle: 'All time orders',
        ),
        _buildStatCard(
          title: "Today's Orders",
          value: '${_stats['todayOrders']}',
          icon: Icons.today,
          color: Colors.green,
          subtitle: 'Orders today',
        ),
        _buildStatCard(
          title: 'Total Revenue',
          value: '\$${(_stats['totalRevenue'] as double).toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.orange,
          subtitle: 'From closed orders',
        ),
        _buildStatCard(
          title: 'Tables',
          value: '${_stats['occupiedTables']}/${_stats['totalTables']}',
          icon: Icons.table_restaurant,
          color: Colors.purple,
          subtitle: 'Occupied / Total',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
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
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
