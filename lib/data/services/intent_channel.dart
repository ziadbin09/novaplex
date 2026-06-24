import 'package:flutter/services.dart';

/// Receives video URIs from Android "Open with" VIEW intents.
class IntentChannel {
  static const _ch = MethodChannel('com.novaplex/intent');

  static void Function(String uri)? onNewUri;
  static bool _handlerInstalled = false;

  static void installHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'onNewUri') {
        final uri = call.arguments as String?;
        if (uri != null) onNewUri?.call(uri);
      }
    });
  }

  /// The URI the app was cold-started with, or null. Cleared after read.
  static Future<String?> getInitialUri() async {
    try {
      return await _ch.invokeMethod<String>('getInitialUri');
    } catch (_) {
      return null;
    }
  }

  /// Open the Android document picker for a video.
  /// Returns the chosen content:// URI, or null if cancelled.
  static Future<String?> pickVideo() async {
    try {
      return await _ch.invokeMethod<String>('pickVideo');
    } catch (_) {
      return null;
    }
  }
}
