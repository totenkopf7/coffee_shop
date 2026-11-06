// core/constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Prefix used inside the QR code. e.g. `COFFEE_TABLE:2`
  static const String qrPrefix = 'COFFEE_TABLE:';

  /// The public web URL that the QR opens (customer menu).
  ///
  /// Priority:
  ///   1. `CUSTOMER_WEB_BASE_URL` from .env (recommended for phones / prod)
  ///   2. Fallback to the current web origin if running on web
  ///   3. Fallback to a LAN default for local development
  ///
  /// Never hardcode a LAN IP in source — it will not work on a phone
  /// that is not on the same Wi-Fi or when the backend is deployed.
  static String get customerWebBaseUrl {
    final fromEnv = dotenv.maybeGet('CUSTOMER_WEB_BASE_URL');
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return _stripTrailingSlash(fromEnv.trim());
    }
    return 'http://192.168.1.13:5004';
  }

  static String _stripTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

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
