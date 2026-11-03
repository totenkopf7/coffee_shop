import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';

class ScanScreen extends StatefulWidget {
  final void Function(String raw) onScanned;

  const ScanScreen({super.key, required this.onScanned});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  void _handle(String raw) {
    if (_handled) return;
    _handled = true;
    _controller.stop();
    widget.onScanned(raw);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _handled = false;
    });
  }

  Future<void> _manualEntry() async {
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
    _handle('${AppConstants.qrPrefix}$n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan the QR on your table'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: kIsWeb
          ? _webFallback()
          : Column(
              children: [
                Expanded(
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      for (final b in capture.barcodes) {
                        final raw = b.rawValue;
                        if (raw != null && raw.isNotEmpty) {
                          _handle(raw);
                          return;
                        }
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black,
                  child: Column(
                    children: [
                      const Text(
                        'Point your camera at the QR code on your table.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.caramel,
                        ),
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Enter table number manually'),
                        onPressed: _manualEntry,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _webFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2, size: 100, color: Colors.white54),
            const SizedBox(height: 20),
            const Text(
              'QR scanning is available on mobile only.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter table number'),
              onPressed: _manualEntry,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}