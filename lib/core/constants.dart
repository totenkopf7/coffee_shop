// lib/core/constants.dart
import 'config.dart';

class AppConstants {
  AppConstants._();

  static const String qrPrefix = 'COFFEE_TABLE:';

  static String get customerWebBaseUrl => AppConfig.customerWebBaseUrl;
  static const int tableCount = AppConfig.tableCount;
  static const String currency = AppConfig.currency;

  static const String channelTables = 'realtime:tables';
  static const String channelSessions = 'realtime:sessions';
  static const String channelOrders = 'realtime:orders';

  /// Paths as declared in pubspec.yaml (keep the `assets/` prefix — the
  /// SoundService strips it for `AudioPlayer` at play time).
  static const String checkRequestSound = 'assets/sounds/check.mp3';
  static const String newOrderSound = 'assets/sounds/new_order.mp3';

  static const String tableStatusAvailable = 'available';
  static const String tableStatusOccupied = 'occupied';
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
