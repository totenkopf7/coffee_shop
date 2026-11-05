// core/constants.dart
class AppConstants {
  AppConstants._();

  static const String qrPrefix = 'COFFEE_TABLE:';
  static const int tableCount = 8;
  static const String currency = '\$';
  static const String channelTables = 'realtime:tables';
  static const String channelSessions = 'realtime:sessions';
  static const String channelOrders = 'realtime:orders';
  static const String checkRequestSound = 'assets/sounds/check_request.mp3';
  static const String newOrderSound = 'assets/sounds/new_order.mp3';
  static const String tableStatusAvailable = 'available';
  static const String tableStatusOccupied = 'occupied';

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

  static String customerMenuUrlFor(int tableNumber) =>
      '$customerWebBaseUrl/#/menu?table=$tableNumber';
}

class SessionStatus {
  SessionStatus._();
  static const String open = 'open';
  static const String checkRequested = 'check_requested';
  static const String closed = 'closed';
  static const List<String> all = [open, checkRequested, closed];
}

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
