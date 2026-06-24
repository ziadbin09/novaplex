import 'dart:async';
import 'package:flutter/services.dart';

class PipChannel {
  static const _method = MethodChannel('com.novaplex/pip');
  static const _events = EventChannel('com.novaplex/pip_events');

  /// Request Android to enter PiP mode. Returns true if supported.
  static Future<bool> enterPip() async {
    try {
      return await _method.invokeMethod<bool>('enterPip') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Tell native side whether the player is currently open.
  /// Native uses this to decide whether to auto-enter PiP on home press.
  static Future<void> setPlayerActive(bool active) async {
    try {
      await _method.invokeMethod('setPlayerActive', {'active': active});
    } catch (_) {}
  }

  /// Stream that emits true when entering PiP, false when leaving.
  static Stream<bool> get pipModeStream =>
      _events.receiveBroadcastStream().map((e) => e as bool);
}
