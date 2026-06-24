import 'package:flutter/services.dart';

/// Bridges Android MediaSession so play/pause/seek work from the
/// notification shade and lock screen.
class MediaSessionChannel {
  static const _ch = MethodChannel('com.novaplex/media_session');

  static void Function()? onPlay;
  static void Function()? onPause;
  static void Function(Duration position)? onSeek;
  static bool _handlerInstalled = false;

  static void _installHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPlay':
          onPlay?.call();
        case 'onPause':
          onPause?.call();
        case 'onSeek':
          final ms = call.arguments as int? ?? 0;
          onSeek?.call(Duration(milliseconds: ms));
      }
    });
  }

  /// Start the media session and show the notification.
  static Future<void> start(String title) async {
    _installHandler();
    try {
      await _ch.invokeMethod('start', {'title': title});
    } catch (_) {}
  }

  /// Push current playback state to the session/notification.
  static Future<void> update({
    required bool playing,
    required Duration position,
    required Duration duration,
  }) async {
    try {
      await _ch.invokeMethod('update', {
        'playing': playing,
        'positionMs': position.inMilliseconds,
        'durationMs': duration.inMilliseconds,
      });
    } catch (_) {}
  }

  /// Tear down the session and dismiss the notification.
  static Future<void> stop() async {
    onPlay = null;
    onPause = null;
    onSeek = null;
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
  }
}
