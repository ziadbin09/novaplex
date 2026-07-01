import 'package:flutter/services.dart';

/// Bridges Android MediaStore so finished downloads land in the public
/// Movies/Manzar collection (visible in the gallery, survives uninstall).
class StorageChannel {
  static const _method = MethodChannel('com.manzar/storage');

  /// Publish [sourcePath] into the public gallery. Returns a content:// URI
  /// (API 29+) or an absolute file path (API ≤28), or null on failure.
  static Future<String?> saveVideo({
    required String sourcePath,
    required String displayName,
    String mimeType = 'video/mp4',
  }) async {
    try {
      return await _method.invokeMethod<String>('saveVideo', {
        'sourcePath': sourcePath,
        'displayName': displayName,
        'mimeType': mimeType,
      });
    } catch (_) {
      return null;
    }
  }

  /// Delete a saved video by its content:// URI or file path.
  static Future<bool> deleteVideo(String uriOrPath) async {
    try {
      return await _method.invokeMethod<bool>('deleteVideo', {
            'uri': uriOrPath,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
