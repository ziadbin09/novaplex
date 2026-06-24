import 'dart:convert';

enum DownloadStatus { queued, downloading, paused, completed, failed }

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.filePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    required this.createdAt,
    this.error,
  });

  final String id;
  final String url;
  final String title;

  /// Absolute path to the (partial or complete) file on disk.
  final String filePath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final DateTime createdAt;
  final String? error;

  double get progress =>
      totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  bool get isActive =>
      status == DownloadStatus.downloading || status == DownloadStatus.queued;

  bool get isComplete => status == DownloadStatus.completed;

  DownloadTask copyWith({
    String? filePath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    String? error,
  }) =>
      DownloadTask(
        id: id,
        url: url,
        title: title,
        filePath: filePath ?? this.filePath,
        totalBytes: totalBytes ?? this.totalBytes,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        status: status ?? this.status,
        createdAt: createdAt,
        error: error ?? this.error,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'filePath': filePath,
        'totalBytes': totalBytes,
        'downloadedBytes': downloadedBytes,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'error': error,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id'] as String,
        url: json['url'] as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String,
        totalBytes: json['totalBytes'] as int? ?? 0,
        downloadedBytes: json['downloadedBytes'] as int? ?? 0,
        status: DownloadStatus
            .values[(json['status'] as int? ?? 0).clamp(0, DownloadStatus.values.length - 1)],
        createdAt: DateTime.parse(json['createdAt'] as String),
        error: json['error'] as String?,
      );

  static List<DownloadTask> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => DownloadTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<DownloadTask> tasks) =>
      jsonEncode(tasks.map((e) => e.toJson()).toList());
}
