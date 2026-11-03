import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/coffee_table.dart';
import '../../models/table_session.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'scan_screen.dart';
import 'customer_menu_screen.dart';

/// Entry point for customer mode.
///
/// - If [tableNumber] is provided (web deep link or from Scan), we validate it.
/// - Otherwise we show the Scan QR screen.
class CustomerEntryScreen extends StatefulWidget {
  final int? tableNumber;

  const CustomerEntryScreen({super.key, this.tableNumber});

  @override
  State<CustomerEntryScreen> createState() => _CustomerEntryScreenState();
}

class _CustomerEntryScreenState extends State<CustomerEntryScreen> {
  final _service = SupabaseService.instance;

  bool _loading = false;
  String? _error;
  CoffeeTable? _table;
  TableSession? _session;

  @override
  void initState() {
    super.initState();
    if (widget.tableNumber != null) {
      _validate(widget.tableNumber!);
    }
  }

  Future<void> _validate(int tableNumber) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final table = await _service.getTableByNumber(tableNumber);
      if (table == null) {
        setState(() {
          _error = 'Table $tableNumber does not exist.';
          _loading = false;
        });
        return;
      }
      if (!table.isOpen) {
        setState(() {
          _table = table;
          _session = null;
          _loading = false;
        });
        return;
      }
      final session = await _service.getActiveSessionForTable(tableNumber);
      setState(() {
        _table = table;
        _session = session;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to open the table: $e';
        _loading = false;
      });
    }
  }

  void _onScanned(String raw) {
    // QR content format: "COFFEE_TABLE:2"
    final parts = raw.split(':');
    if (parts.length != 2) {
      _showSnack('Invalid QR code.');
      return;
    }
    final n = int.tryParse(parts[1]);
    if (n == null) {
      _showSnack('Invalid table number.');
      return;
    }
    _validate(n);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // No table yet → show the scanner.
    if (widget.tableNumber == null && _table == null && !_loading) {
      return ScanScreen(
        onScanned: _onScanned,
      );
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: LoadingWidget(message: 'Warming up the espresso machine...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Coffee Shop')),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Something went wrong',
          subtitle: _error,
          action: ElevatedButton(
            onPressed: () {
              if (widget.tableNumber != null) {
                _validate(widget.tableNumber!);
              } else {
                setState(() {
                  _table = null;
                  _session = null;
                  _error = null;
                });
              }
            },
            child: const Text('Try again'),
          ),
        ),
      );
    }

    // Table exists but is closed → friendly "ask staff" message.
    if (_table != null && (_session == null || _session!.isClosed)) {
      return _TableClosedView(tableNumber: _table!.tableNumber);
    }

    // Table is open → menu.
    if (_table != null && _session != null) {
      return CustomerMenuScreen(
        table: _table!,
        session: _session!,
      );
    }

    return const Scaffold(
      backgroundColor: AppColors.cream,
      body: LoadingWidget(),
    );
  }
}

class _TableClosedView extends StatelessWidget {
  final int tableNumber;
  const _TableClosedView({required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☕', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                'Table $tableNumber is closed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.espresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please ask a member of staff to open this table for you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
