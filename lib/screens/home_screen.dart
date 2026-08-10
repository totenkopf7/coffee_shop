import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/coffee_table.dart';
import '../widgets/table_card.dart';
import 'table_screen.dart';

/// The main dashboard screen showing all tables
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CoffeeTable> _tables = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  /// Load tables from Supabase
  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = SupabaseService();
      final tables = await service.getTables();

      print('Loaded ${tables.length} tables'); // DEBUG

      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tables: $e'); // DEBUG
      setState(() {
        _error = 'Failed to load tables: $e';
        _isLoading = false;
      });
    }
  }

  void _refreshTables() {
    _loadTables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '☕ Coffee Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTables,
            tooltip: 'Refresh tables',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tables...'),
          ],
        ),
      );
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
              onPressed: _refreshTables,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tables found. Please run the SQL setup.'),
            SizedBox(height: 8),
            Text(
              'Make sure the "tables" table has data.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: _tables.length,
        itemBuilder: (context, index) {
          final table = _tables[index];
          return TableCard(
            table: table,
            onTap: () => _openTable(table),
          );
        },
      ),
    );
  }

  void _openTable(CoffeeTable table) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableScreen(table: table),
      ),
    );

    if (result == true) {
      _refreshTables();
    }
  }
}
