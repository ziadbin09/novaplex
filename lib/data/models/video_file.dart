import 'package:flutter/foundation.dart';

@immutable
class VideoFile {
  const VideoFile({
    required this.id,
    required this.title,
    required this.path,
    required this.duration,
    required this.size,
    required this.dateAdded,
    this.thumbnailData,
    this.width = 0,
    this.height = 0,
    this.mimeType = '',
    this.folderName = '',
  });

  final String id;
  final String title;
  final String path;
  final Duration duration;
  final int size;
  final DateTime dateAdded;
  final Uint8List? thumbnailData;
  final int width;
  final int height;
  final String mimeType;
  final String folderName;

  String get resolutionLabel {
    if (height >= 2160) return '4K';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    if (height > 0) return '${height}p';
    return '';
  }

  VideoFile copyWith({Uint8List? thumbnailData}) => VideoFile(
        id: id,
        title: title,
        path: path,
        duration: duration,
        size: size,
        dateAdded: dateAdded,
        thumbnailData: thumbnailData ?? this.thumbnailData,
        width: width,
        height: height,
        mimeType: mimeType,
        folderName: folderName,
      );
}
