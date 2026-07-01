import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

class ShareChannel {
  static const _method = MethodChannel('com.manzar/share');

  /// Share a local video by its photo_manager asset ID.
  /// Resolves the content:// URI from photo_manager, then fires Android share intent.
  static Future<void> shareVideo(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    final uri = await asset?.getMediaUrl();
    if (uri == null) return;
    await _method.invokeMethod('shareVideo', {'uri': uri});
  }
}
