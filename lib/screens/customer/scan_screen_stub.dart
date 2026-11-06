// screens/customer/scan_screen_stub.dart
//
// Web stub. Never instantiated at runtime (ScanScreen checks kIsWeb first),
// but needed so the compiler resolves the conditional import.
import 'package:flutter/material.dart';

Widget buildMobileScanner({
  required void Function(String raw) onScanned,
  required VoidCallback onManualEntry,
}) {
  return const Center(
    child: Text(
      'QR scanning is not available on this platform.',
      style: TextStyle(color: Colors.white70),
    ),
  );
}
