// screens/customer/scan_screen_mobile.dart
//
// Real scanner implementation. This file is only compiled on mobile
// (non-web) platforms via the conditional import in scan_screen.dart.
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_colors.dart';

Widget buildMobileScanner({
  required void Function(String raw) onScanned,
  required VoidCallback onManualEntry,
}) {
  return _MobileScannerScreen(
    onScanned: onScanned,
    onManualEntry: onManualEntry,
  );
}

class _MobileScannerScreen extends StatefulWidget {
  final void Function(String raw) onScanned;
  final VoidCallback onManualEntry;

  const _MobileScannerScreen({
    required this.onScanned,
    required this.onManualEntry,
  });

  @override
  State<_MobileScannerScreen> createState() => _MobileScannerScreenState();
}

class _MobileScannerScreenState extends State<_MobileScannerScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan the QR on your table'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
                  onPressed: widget.onManualEntry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
