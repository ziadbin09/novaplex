import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/video_file.dart';
import '../../core/constants/app_constants.dart';

class VideoApiException implements Exception {
  final String message;
  const VideoApiException(this.message);
  @override
  String toString() => message;
}

/// Fetches video metadata from PocketBase on Railway.
class VideoApiService {
  static Future<VideoFile> fetchVideo(String id) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        '${AppConstants.pocketbaseUrl}/api/collections/videos/records/$id',
      );
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        throw const VideoApiException('Video not found.');
      }
      if (response.statusCode != 200) {
        throw VideoApiException('Server error (${response.statusCode}).');
      }

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final streamUrl = data['stream_url'] as String?;
      if (streamUrl == null || streamUrl.isEmpty) {
        throw const VideoApiException('Video has no stream URL.');
      }

      return VideoFile(
        id: data['id'] as String,
        title: data['title'] as String? ?? 'Untitled',
        path: streamUrl,
        duration: Duration(seconds: (data['duration'] as num?)?.toInt() ?? 0),
        size: (data['size'] as num?)?.toInt() ?? 0,
        dateAdded: DateTime.tryParse(data['created'] as String? ?? '') ?? DateTime.now(),
        mimeType: data['mime_type'] as String? ?? 'video/mp4',
      );
    } on VideoApiException {
      rethrow;
    } on SocketException {
      throw const VideoApiException('No internet connection.');
    } on TimeoutException {
      throw const VideoApiException('Request timed out. Check your connection.');
    } catch (e) {
      throw VideoApiException('Unexpected error: $e');
    } finally {
      client.close();
    }
  }
}
