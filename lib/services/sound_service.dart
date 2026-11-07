// services/sound_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:just_audio/just_audio.dart';

import '../core/constants.dart';

/// Reliable cross-platform alert sounds using `just_audio`.
///
/// Two independent players (one per sound) so a check alert can overlap
/// a new-order alert. Each player loads its file once at app start;
/// replay is `seekTo(0) + play()`.
///
/// Format: WAV (PCM) — decoded natively everywhere.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _checkPlayer = AudioPlayer();
  final AudioPlayer _orderPlayer = AudioPlayer();

  bool _initialized = false;

  DateTime _lastCheck = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastOrder = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _debounce = Duration(seconds: 2);

  /// Load both assets once. Safe to call repeatedly.
  ///
  /// `just_audio` (0.4.0+) automatically configures the audio session
  /// to `playback` category by default, so alerts play even when the
  /// phone is on silent mode. No manual session setup needed.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _checkPlayer.setLoopMode(LoopMode.off);
      await _orderPlayer.setLoopMode(LoopMode.off);
      await _checkPlayer.setVolume(1.0);
      await _orderPlayer.setVolume(1.0);

      await Future.wait([
        _checkPlayer.setAsset(AppConstants.checkRequestSound),
        _orderPlayer.setAsset(AppConstants.newOrderSound),
      ]);

      _initialized = true;
      debugPrint('SoundService: initialized and preloaded');
    } catch (e) {
      debugPrint('SoundService: init error → $e');
      debugPrint(
        'SoundService: check that pubspec.yaml declares '
        '"${AppConstants.checkRequestSound}" and '
        '"${AppConstants.newOrderSound}", and that those files exist.',
      );
    }
  }

  Future<void> _replay(AudioPlayer player) async {
    try {
      await player.stop();
      await player.seek(Duration.zero);
      unawaited(player.play());
    } catch (e) {
      debugPrint('SoundService: replay error → $e');
    }
  }

  Future<void> playCheckRequest() async {
    if (!_initialized) await init();
    if (DateTime.now().difference(_lastCheck) < _debounce) return;
    _lastCheck = DateTime.now();
    debugPrint('SoundService: playing ${AppConstants.checkRequestSound}');
    await _replay(_checkPlayer);
  }

  Future<void> playNewOrder() async {
    if (!_initialized) await init();
    if (DateTime.now().difference(_lastOrder) < _debounce) return;
    _lastOrder = DateTime.now();
    debugPrint('SoundService: playing ${AppConstants.newOrderSound}');
    await _replay(_orderPlayer);
  }

  Future<void> dispose() async {
    await _checkPlayer.dispose();
    await _orderPlayer.dispose();
  }
}
