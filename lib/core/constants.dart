// core\constants.dart
/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Prefix used inside the QR code. e.g. `COFFEE_TABLE:2`
  static const String qrPrefix = 'COFFEE_TABLE:';

  /// Total number of tables in the shop.
  static const int tableCount = 8;

  /// Currency symbol.
  static const String currency = '\$';

  /// Realtime channel names.
  static const String channelTables = 'realtime:tables';
  static const String channelSessions = 'realtime:sessions';
  static const String channelOrders = 'realtime:orders';

  /// Sound asset paths.
  static const String checkRequestSound = 'assets/sounds/check_request.mp3';
  static const String newOrderSound = 'assets/sounds/new_order.mp3';

  /// Table `status` column values (matches DB check constraint).
  static const String tableStatusAvailable = 'available';
  static const String tableStatusOccupied = 'occupied';

  /// Base URL of the customer-facing web app (used inside generated QR codes).
  ///
  /// We derive this at runtime from whatever URL the staff's browser is
  /// currently on. That URL is guaranteed to be reachable from a phone
  /// (since the staff device just loaded it), which avoids the classic
  /// "QR points to 0.0.0.0 / localhost" bug when the app is deployed.
  ///
  /// - On Vercel: `https://your-app.vercel.app`
  /// - On LAN:    `http://192.168.1.42:5004`
  /// - On desktop: `http://localhost:5004`
  ///
  /// Falls back to `customerWebBaseUrlOverride` if we can't read the
  /// current URL (should never happen in web builds).
  static String get customerWebBaseUrl {
    final override = const String.fromEnvironment('CUSTOMER_WEB_BASE_URL');
    if (override.isNotEmpty) return override;

    try {
      final u = Uri.base;
      final scheme = u.scheme.isEmpty ? 'http' : u.scheme;
      final host = u.host.isEmpty ? 'localhost' : u.host;
      final port = u.hasPort ? ':${u.port}' : '';
      return '$scheme://$host$port';
    } catch (_) {
      return 'http://localhost:5004';
    }
  }

  /// Convenience: full customer menu URL for a given table number.
  static String customerMenuUrlFor(int tableNumber) =>
      '$customerWebBaseUrl/#/menu?table=$tableNumber';
}

/// Session status values — must match the DB check constraint.
class SessionStatus {
  SessionStatus._();
  static const String open = 'open';
  static const String checkRequested = 'check_requested';
  static const String closed = 'closed';

  static const List<String> all = [open, checkRequested, closed];
}

/// Order status values — must match the DB check constraint.
class OrderStatus {
  OrderStatus._();
  static const String open = 'open';
  static const String placed = 'placed';
  static const String preparing = 'preparing';
  static const String served = 'served';
  static const String checkRequested = 'check_requested';
  static const String closed = 'closed';

  static const List<String> all = [
    open,
    placed,
    preparing,
    served,
    checkRequested,
    closed,
  ];
}
