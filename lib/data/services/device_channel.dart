import 'package:flutter/services.dart';

/// Bridges native device-capability checks.
class DeviceChannel {
  static const _method = MethodChannel('com.novaplex/device');

  /// True when running on an emulator / Android-on-PC (e.g. BlueStacks),
  /// where hardware video decoding renders a frozen frame. Defaults to false
  /// (assume a real device) if the check fails.
  static Future<bool> isLikelyEmulator() async {
    try {
      return await _method.invokeMethod<bool>('isLikelyEmulator') ?? false;
    } catch (_) {
      return false;
    }
  }
}
