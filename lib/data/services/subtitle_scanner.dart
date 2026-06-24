import 'dart:io';
import 'package:path/path.dart' as p;

class SubtitleFile {
  const SubtitleFile({required this.path, required this.label});
  final String path;
  final String label;

  String get uri => 'file://$path';
}

class SubtitleScanner {
  static const _extensions = ['.srt', '.ass', '.ssa', '.sub', '.vtt'];

  /// Scans for subtitle files alongside [videoPath].
  /// Returns a list of found subtitle files.
  static List<SubtitleFile> scan(String videoPath) {
    final dir = p.dirname(videoPath);
    final base = p.basenameWithoutExtension(videoPath);
    final results = <SubtitleFile>[];

    for (final ext in _extensions) {
      // Exact match: video.srt
      final exact = File(p.join(dir, '$base$ext'));
      if (exact.existsSync()) {
        results.add(SubtitleFile(
          path: exact.path,
          label: ext.substring(1).toUpperCase(),
        ));
      }
    }

    // Also scan directory for files starting with the base name
    try {
      final dirEntity = Directory(dir);
      if (dirEntity.existsSync()) {
        for (final entity in dirEntity.listSync()) {
          if (entity is! File) continue;
          final name = p.basename(entity.path).toLowerCase();
          final ext = p.extension(entity.path).toLowerCase();
          if (!_extensions.contains(ext)) continue;
          // Already added above
          if (p.basenameWithoutExtension(entity.path) == base) continue;
          // Match patterns like video.en.srt / video.English.srt
          if (name.startsWith(base.toLowerCase())) {
            final label = p
                .basenameWithoutExtension(entity.path)
                .replaceFirst(base, '')
                .replaceAll('.', ' ')
                .trim();
            results.add(SubtitleFile(
              path: entity.path,
              label: label.isEmpty
                  ? ext.substring(1).toUpperCase()
                  : label,
            ));
          }
        }
      }
    } catch (_) {}

    return results;
  }
}
