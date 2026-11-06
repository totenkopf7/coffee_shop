// services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// Plays alert sounds on the employee dashboard:
///   • assets/sounds/new_order.mp3 → a customer placed a new order
///   • assets/sounds/check.mp3     → a customer requested the check
///
/// Two independent [AudioPlayer]s so a check alert can overlap a new-order
/// alert. Debounced (2 s per event type) so a burst of realtime events
/// triggers exactly one sound.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _checkPlayer = AudioPlayer();
  final AudioPlayer _orderPlayer = AudioPlayer();

  DateTime _lastCheck = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastOrder = DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _debounce = Duration(seconds: 2);

  bool _initialized = false;

  /// Call once at app startup. Safe to call multiple times.
  ///
  /// Sets the OS audio session to "playback" (Android/iOS) so the alert
  /// plays even when the phone is on silent mode. On web this is a no-op.
  Future<void> init() async {
    if (_initialized) return;
    try {
      // Global context: play as music/alert, not as a ringtone/interruption.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            audioMode: AndroidAudioMode.normal,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const [AVAudioSessionOptions.mixWithOthers],
          ),
        ),
      );
      _initialized = true;
      debugPrint('SoundService: initialized');
    } catch (e) {
      debugPrint('SoundService: init error (non-fatal): $e');
    }
  }

  Future<void> _play(
    AudioPlayer player,
    DateTime last,
    String asset,
  ) async {
    if (DateTime.now().difference(last) < _debounce) {
      debugPrint('SoundService: skipped (debounced) → $asset');
      return;
    }

    // AudioPlayer resolves asset paths relative to `assets/`, so we must
    // strip the leading `assets/`.
    final relativePath =
        asset.startsWith('assets/') ? asset.substring('assets/'.length) : asset;

    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);

      // setSourceAsset is more reliable than play(AssetSource(...)) on web,
      // iOS, and macOS. Then resume() starts playback.
      await player.setSourceAsset(relativePath);
      await player.resume();

      debugPrint('SoundService: played → $relativePath');
    } catch (e) {
      debugPrint('SoundService: FAILED to play "$asset": $e');
      debugPrint(
        'SoundService: check that pubspec.yaml declares "$asset" '
        'and that the file exists on disk.',
      );
    }
  }

  Future<void> playCheckRequest() async {
    if (DateTime.now().difference(_lastCheck) < _debounce) return;
    _lastCheck = DateTime.now();
    await _play(_checkPlayer, _lastCheck, AppConstants.checkRequestSound);
  }

  Future<void> playNewOrder() async {
    if (DateTime.now().difference(_lastOrder) < _debounce) return;
    _lastOrder = DateTime.now();
    await _play(_orderPlayer, _lastOrder, AppConstants.newOrderSound);
  }

  Future<void> dispose() async {
    await _checkPlayer.dispose();
    await _orderPlayer.dispose();
  }
}
