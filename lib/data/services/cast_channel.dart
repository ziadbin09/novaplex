import 'dart:async';
import 'package:flutter/services.dart';

/// Mirrors Android's CastState constants.
enum CastState {
  noDevices, // 1 — no Cast devices on the network
  notConnected, // 2 — devices available, not connected
  connecting, // 3
  connected, // 4
}

CastState _stateFromInt(int v) {
  switch (v) {
    case 4:
      return CastState.connected;
    case 3:
      return CastState.connecting;
    case 2:
      return CastState.notConnected;
    default:
      return CastState.noDevices;
  }
}

/// Bridge to the native Google Cast SDK.
class CastChannel {
  static const _method = MethodChannel('com.novaplex/cast');
  static const _events = EventChannel('com.novaplex/cast_events');

  /// True if Google Play Services + Cast are available on this device.
  static Future<bool> isAvailable() async {
    try {
      return await _method.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<CastState> getState() async {
    try {
      final v = await _method.invokeMethod<int>('getState') ?? 1;
      return _stateFromInt(v);
    } catch (_) {
      return CastState.noDevices;
    }
  }

  /// Open the native Cast device chooser dialog.
  static Future<void> showPicker() async {
    try {
      await _method.invokeMethod('showPicker');
    } catch (_) {}
  }

  /// Load a media URL onto the connected Cast device.
  static Future<bool> loadMedia({
    required String url,
    required String title,
    String contentType = 'video/mp4',
    Duration position = Duration.zero,
  }) async {
    try {
      return await _method.invokeMethod<bool>('loadMedia', {
            'url': url,
            'title': title,
            'contentType': contentType,
            'positionMs': position.inMilliseconds,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> play() async {
    try {
      await _method.invokeMethod('play');
    } catch (_) {}
  }

  static Future<void> pause() async {
    try {
      await _method.invokeMethod('pause');
    } catch (_) {}
  }

  static Future<void> seek(Duration position) async {
    try {
      await _method.invokeMethod('seek', {'positionMs': position.inMilliseconds});
    } catch (_) {}
  }

  /// End the current Cast session and stop playback on the device.
  static Future<void> stop() async {
    try {
      await _method.invokeMethod('stop');
    } catch (_) {}
  }

  /// Stream of cast state changes. Emits a [CastState] on every change, plus
  /// dedicated connected/disconnected transitions via [connectionStream].
  static Stream<CastEvent> get events =>
      _events.receiveBroadcastStream().map((e) {
        final map = (e as Map).cast<String, dynamic>();
        switch (map['type'] as String?) {
          case 'connected':
            return const CastEvent.connected();
          case 'disconnected':
            return const CastEvent.disconnected();
          case 'state':
            return CastEvent.state(_stateFromInt(map['state'] as int? ?? 1));
          default:
            return const CastEvent.state(CastState.noDevices);
        }
      });
}

/// An event from the native cast bridge.
class CastEvent {
  const CastEvent.state(this.state)
      : connected = false,
        disconnected = false;
  const CastEvent.connected()
      : state = CastState.connected,
        connected = true,
        disconnected = false;
  const CastEvent.disconnected()
      : state = CastState.notConnected,
        connected = false,
        disconnected = true;

  final CastState state;
  final bool connected;
  final bool disconnected;
}
