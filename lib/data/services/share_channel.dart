import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

class ShareChannel {
  static const _method = MethodChannel('com.manzar/share');

  /// Share a local video by its photo_manager asset ID.
  /// Resolves the content:// URI from photo_manager, then fires Android share intent.
  /// Returns true on success, false if the asset couldn't be resolved or the
  /// native share intent failed (e.g. the file was deleted moments earlier).
  static Future<bool> shareVideo(String assetId) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      final uri = await asset?.getMediaUrl();
      if (uri == null) return false;
      await _method.invokeMethod('shareVideo', {'uri': uri});
      return true;
    } catch (_) {
      return false;
    }
  }
}
