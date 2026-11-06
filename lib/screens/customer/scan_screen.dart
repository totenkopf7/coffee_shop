import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';

// Conditional import — dart.library.io exists on mobile, not on web.
import 'scan_screen_mobile.dart' if (dart.library.html) 'scan_screen_stub.dart';

class ScanScreen extends StatelessWidget {
  final void Function(String raw) onScanned;
  const ScanScreen({super.key, required this.onScanned});

  Future<void> _manualEntry(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter table number'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 2'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final n = int.tryParse(result);
    if (n == null) return;
    onScanned('${AppConstants.qrPrefix}$n');
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _webFallback(context);
    return buildMobileScanner(
      onScanned: onScanned,
      onManualEntry: () => _manualEntry(context),
    );
  }

  Widget _webFallback(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan the QR on your table'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, size: 100, color: Colors.white54),
              const SizedBox(height: 20),
              const Text(
                'QR scanning is available on mobile only.\n'
                'On the web, please use the QR link on your table or '
                'enter the table number below.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.keyboard),
                label: const Text('Enter table number'),
                onPressed: () => _manualEntry(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
