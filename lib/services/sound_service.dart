import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// Plays alert sounds. Debounced per key so we don't fire 5 times
/// when 5 realtime events arrive at once.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _checkPlayer = AudioPlayer();
  final AudioPlayer _orderPlayer = AudioPlayer();

  DateTime _lastCheck = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastOrder = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _play(
    AudioPlayer player,
    DateTime last,
    String asset,
    Duration debounce,
  ) async {
    if (DateTime.now().difference(last).inMilliseconds <
        debounce.inMilliseconds) {
      return;
    }
    try {
      await player.stop();
      final path = asset.replaceFirst('assets/', '');
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('SoundService error: $e');
    }
  }

  /// Louder, more urgent sound when a customer requests the check.
  Future<void> playCheckRequest() async {
    if (DateTime.now().difference(_lastCheck).inSeconds < 2) return;
    _lastCheck = DateTime.now();
    await _play(
      _checkPlayer,
      _lastCheck,
      AppConstants.checkRequestSound,
      const Duration(seconds: 2),
    );
  }

  /// Softer "ding" when a new order comes in.
  Future<void> playNewOrder() async {
    if (DateTime.now().difference(_lastOrder).inSeconds < 2) return;
    _lastOrder = DateTime.now();
    await _play(
      _orderPlayer,
      _lastOrder,
      AppConstants.newOrderSound,
      const Duration(seconds: 2),
    );
  }

  Future<void> dispose() async {
    await _checkPlayer.dispose();
    await _orderPlayer.dispose();
  }
}
