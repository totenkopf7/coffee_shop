// screens\customer\customer_entry_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/coffee_table.dart';
import '../../models/table_session.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'scan_screen.dart';
import 'customer_menu_screen.dart';

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
  String? _errorHint;
  bool _networkIssue = false;

  CoffeeTable? _table;
  TableSession? _session;

  Timer? _watchdog;

  static const _watchdogDuration = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    final n = widget.tableNumber;
    if (n != null && n > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _validate(n);
      });
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  /// Watchdog: if `_loading` is still true after N seconds, force the
  /// error state so the user is never trapped on a spinner.
  void _armWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(_watchdogDuration, () {
      if (!mounted) return;
      if (!_loading) return;
      setState(() {
        _loading = false;
        _networkIssue = true;
        _error = 'Cannot reach the coffee shop.';
        _errorHint =
            'The request took too long. Check your Wi-Fi / internet, then '
            'tap Try again.';
      });
    });
  }

  Future<void> _validate(int tableNumber) async {
    if (!mounted) return;
    _armWatchdog();
    setState(() {
      _loading = true;
      _error = null;
      _errorHint = null;
      _networkIssue = false;
    });

    try {
      // ── Step 1: table ────────────────────────────────────────────
      final table = await _service
          .getTableByNumber(tableNumber)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;

      if (table == null) {
        _watchdog?.cancel();
        setState(() {
          _loading = false;
          _error = 'Table $tableNumber does not exist.';
          _errorHint = 'Check the QR code or ask a member of staff for help.';
        });
        return;
      }

      if (!table.isOpen) {
        _watchdog?.cancel();
        setState(() {
          _table = table;
          _session = null;
          _loading = false;
        });
        return;
      }

      // ── Step 2: session ───────────────────────────────────────────
      final session = await _service
          .getActiveSessionForTable(tableNumber)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;

      _watchdog?.cancel();
      setState(() {
        _table = table;
        _session = session;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _watchdog?.cancel();
      final s = e.toString();
      final isNetwork = s.contains('TimeoutException') ||
          s.contains('SocketException') ||
          s.contains('ClientException') ||
          s.contains('Failed host lookup') ||
          s.contains('Connection') ||
          s.contains('HandshakeException');
      setState(() {
        _loading = false;
        _networkIssue = isNetwork;
        _error = isNetwork
            ? 'Cannot reach the coffee shop.'
            : 'Failed to open the table.';
        _errorHint =
            isNetwork ? 'Please check your connection and try again.' : s;
      });
    }
  }

  void _onScanned(String raw) {
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

  void _retry() {
    final n = widget.tableNumber;
    if (n != null) {
      _validate(n);
    } else {
      setState(() {
        _table = null;
        _session = null;
        _error = null;
        _errorHint = null;
        _networkIssue = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tableNumber == null &&
        _table == null &&
        !_loading &&
        _error == null) {
      return ScanScreen(onScanned: _onScanned);
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
          icon: _networkIssue ? Icons.wifi_off : Icons.error_outline,
          title: _networkIssue ? 'Connection problem' : 'Something went wrong',
          subtitle: _error,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorHint != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorHint!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _retry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_table != null && (_session == null || _session!.isClosed)) {
      return _TableClosedView(tableNumber: _table!.tableNumber);
    }

    if (_table != null && _session != null) {
      return CustomerMenuScreen(
        table: _table!,
        session: _session!,
      );
    }

    return ScanScreen(onScanned: _onScanned);
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
