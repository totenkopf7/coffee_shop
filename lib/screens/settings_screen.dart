import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsCard(
            icon: Icons.table_restaurant,
            title: 'Table Management',
            subtitle: 'Manage table settings and layout',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Table management coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildSettingsCard(
            icon: Icons.restaurant_menu,
            title: 'Menu Management',
            subtitle: 'Add, edit, or remove products',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menu management coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildSettingsCard(
            icon: Icons.print,
            title: 'Printer Settings',
            subtitle: 'Configure receipt printer',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Printer settings coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildSettingsCard(
            icon: Icons.palette,
            title: 'Appearance',
            subtitle: 'Theme and display settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appearance settings coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 32),
          _buildSettingsCard(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Coffee Shop App v1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Coffee Shop',
                applicationVersion: '1.0.0',
                applicationIcon:
                    const Text('☕', style: TextStyle(fontSize: 32)),
                children: [
                  const Text('A simple coffee shop management system.'),
                  const SizedBox(height: 8),
                  const Text('Built with Flutter & Supabase'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.brown[700]),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
