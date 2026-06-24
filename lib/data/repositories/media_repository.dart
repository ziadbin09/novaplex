import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/video_file.dart';
import 'privacy_repository.dart';

final mediaRepositoryProvider = Provider((ref) => MediaRepository());

final videosProvider = FutureProvider<List<VideoFile>>((ref) async {
  return ref.watch(mediaRepositoryProvider).fetchAllVideos();
});

/// All videos except those in hidden folders (unless private is unlocked).
final visibleVideosProvider = Provider<AsyncValue<List<VideoFile>>>((ref) {
  final videosAsync = ref.watch(videosProvider);
  final hidden = ref.watch(hiddenFoldersProvider);
  final unlocked = ref.watch(privateUnlockedProvider);
  if (hidden.isEmpty || unlocked) return videosAsync;
  return videosAsync.whenData(
    (videos) =>
        videos.where((v) => !hidden.contains(v.folderName)).toList(),
  );
});

final videosByFolderProvider =
    Provider<AsyncValue<Map<String, List<VideoFile>>>>((ref) {
  final videosAsync = ref.watch(visibleVideosProvider);
  return videosAsync.whenData((videos) {
    final map = <String, List<VideoFile>>{};
    for (final v in videos) {
      map.putIfAbsent(v.folderName, () => []).add(v);
    }
    return map;
  });
});

/// Thrown when the app has no access to media so the UI can show a
/// "grant access" prompt instead of a misleading "no videos" message.
class MediaPermissionException implements Exception {
  const MediaPermissionException();
}

class MediaRepository {
  /// Request media access. Returns true if granted (full OR limited).
  Future<bool> ensureAccess() async {
    final ps = await PhotoManager.requestPermissionExtend();
    return ps.hasAccess;
  }

  /// Open the system settings page for this app (for permanently-denied case).
  Future<void> openSettings() => PhotoManager.openSetting();

  Future<List<VideoFile>> fetchAllVideos() async {
    final ps = await PhotoManager.requestPermissionExtend();
    // hasAccess covers both full and "selected photos" (Android 14) access.
    if (!ps.hasAccess) {
      throw const MediaPermissionException();
    }

    // Explicit orderBy is required: without it photo_manager emits
    // "ORDER BY LIMIT n" (empty clause) which crashes on older Android
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: false,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    final seen = <String>{};
    final videos = <VideoFile>[];

    for (final album in albums) {
      final count = await album.assetCountAsync;
      final assets = await album.getAssetListRange(start: 0, end: count);
      for (final asset in assets) {
        if (seen.contains(asset.id)) continue;
        seen.add(asset.id);
        final file = await asset.file;
        if (file == null) continue;
        videos.add(VideoFile(
          id: asset.id,
          title: asset.title ?? file.path.split('/').last,
          path: file.path,
          duration: asset.videoDuration,
          size: await file.length(),
          dateAdded: asset.createDateTime,
          width: asset.width,
          height: asset.height,
          folderName: album.isAll ? 'All Videos' : album.name,
        ));
      }
    }

    videos.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return videos;
  }
}
