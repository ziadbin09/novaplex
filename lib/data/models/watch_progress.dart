import 'package:flutter/foundation.dart';

@immutable
class WatchProgress {
  const WatchProgress({
    required this.videoId,
    required this.position,
    required this.duration,
    required this.lastWatched,
  });

  final String videoId;
  final Duration position;
  final Duration duration;
  final DateTime lastWatched;

  double get percent =>
      duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0;

  bool get isFinished => percent > 0.92;

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'position': position.inSeconds,
        'duration': duration.inSeconds,
        'lastWatched': lastWatched.millisecondsSinceEpoch,
      };

  factory WatchProgress.fromJson(Map<String, dynamic> json) => WatchProgress(
        videoId: json['videoId'] as String,
        position: Duration(seconds: json['position'] as int),
        duration: Duration(seconds: json['duration'] as int),
        lastWatched:
            DateTime.fromMillisecondsSinceEpoch(json['lastWatched'] as int),
      );
}
