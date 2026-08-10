import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/coffee_table.dart';
import '../widgets/table_card.dart';
import 'table_screen.dart';
import 'settings_screen.dart';
import 'orders_screen.dart';
import 'reports_screen.dart';

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

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = SupabaseService();
      final tables = await service.getTables();
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
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
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTables,
            tooltip: 'Refresh tables',
          ),
        ],
      ),
      // Add the drawer
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.brown[800],
            ),
            child: Column(
              children: [
                const Text(
                  '☕',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coffee Shop',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Management System',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                  },
                  isSelected: true,
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long,
                  title: 'Orders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrdersScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart,
                  title: 'Reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReportsScreen()),
                    );
                  },
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Coffee Shop',
                      applicationVersion: '1.0.0',
                      applicationIcon:
                          const Text('☕', style: TextStyle(fontSize: 32)),
                      children: const [
                        Text('A simple coffee shop management system.'),
                        SizedBox(height: 8),
                        Text('Built with Flutter & Supabase'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '© 2024 Coffee Shop',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.brown[700] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.brown[700] : Colors.grey[800],
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.brown[700],
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.brown[50],
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
            Text('No tables found'),
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
