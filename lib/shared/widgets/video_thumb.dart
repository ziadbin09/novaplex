import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/video_file.dart';

/// Lazily loads and displays a video's thumbnail.
///
/// Order of resolution:
/// 1. `video.thumbnailData` if already present
/// 2. MediaStore thumbnail via the asset id (device/library videos)
/// 3. Generated from the file path via video_thumbnail (downloads / local files)
///
/// Results are cached in-memory by video id so scrolling doesn't reload.
class VideoThumb extends StatefulWidget {
  const VideoThumb({
    super.key,
    required this.video,
    this.fit = BoxFit.cover,
    this.iconSize = 36,
  });

  final VideoFile video;
  final BoxFit fit;
  final double iconSize;

  static final Map<String, Uint8List?> _cache = {};

  @override
  State<VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<VideoThumb> {
  Uint8List? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // Already attached to the model.
    if (widget.video.thumbnailData != null) {
      _data = widget.video.thumbnailData;
      _loading = false;
      return;
    }
    final id = widget.video.id;
    if (VideoThumb._cache.containsKey(id)) {
      _data = VideoThumb._cache[id];
      _loading = false;
      return;
    }
    // Defer to after first frame so the list paints immediately.
    final thumb = await _load();
    VideoThumb._cache[id] = thumb;
    if (mounted) {
      setState(() {
        _data = thumb;
        _loading = false;
      });
    }
  }

  Future<Uint8List?> _load() async {
    // 1. Try MediaStore asset thumbnail (fast, pre-generated).
    try {
      final asset = await AssetEntity.fromId(widget.video.id);
      if (asset != null) {
        final t = await asset.thumbnailDataWithSize(
          const ThumbnailSize(320, 180),
          quality: 80,
        );
        if (t != null) return t;
      }
    } catch (_) {}

    // 2. Generate from a local file path (downloads / imported files).
    final path = widget.video.path;
    final isLocalFile = !path.startsWith('http') && !path.startsWith('content://');
    if (isLocalFile) {
      try {
        return await VideoThumbnail.thumbnailData(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 320,
          quality: 75,
        );
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_data != null) {
      return Image.memory(
        _data!,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }
    return Container(
      color: colors.surfaceAlt,
      child: Center(
        child: _loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textSecondary,
                ),
              )
            : Icon(Icons.movie_outlined,
                color: colors.textSecondary, size: widget.iconSize),
      ),
    );
  }
}
