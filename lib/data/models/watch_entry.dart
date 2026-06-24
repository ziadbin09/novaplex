import 'dart:convert';

class WatchEntry {
  const WatchEntry({
    required this.videoId,
    required this.videoPath,
    required this.videoTitle,
    required this.positionMs,
    required this.durationMs,
    required this.lastWatched,
  });

  final String videoId;
  final String videoPath;
  final String videoTitle;
  final int positionMs;
  final int durationMs;
  final DateTime lastWatched;

  double get watchPercent =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0;

  bool get isFinished => watchPercent >= 0.95;

  WatchEntry copyWith({int? positionMs, int? durationMs, DateTime? lastWatched}) =>
      WatchEntry(
        videoId: videoId,
        videoPath: videoPath,
        videoTitle: videoTitle,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        lastWatched: lastWatched ?? this.lastWatched,
      );

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'videoPath': videoPath,
        'videoTitle': videoTitle,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'lastWatched': lastWatched.toIso8601String(),
      };

  factory WatchEntry.fromJson(Map<String, dynamic> json) => WatchEntry(
        videoId: json['videoId'] as String,
        videoPath: json['videoPath'] as String,
        videoTitle: json['videoTitle'] as String,
        positionMs: json['positionMs'] as int,
        durationMs: json['durationMs'] as int,
        lastWatched: DateTime.parse(json['lastWatched'] as String),
      );

  static List<WatchEntry> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WatchEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<WatchEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());
}
