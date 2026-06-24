import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/video_file.dart';
import 'settings_repository.dart';

const _kPlaylistsKey = 'playlists_v1';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return PlaylistRepository(prefs);
});

final playlistsProvider =
    NotifierProvider<PlaylistsNotifier, List<Playlist>>(PlaylistsNotifier.new);

class PlaylistsNotifier extends Notifier<List<Playlist>> {
  @override
  List<Playlist> build() =>
      ref.watch(playlistRepositoryProvider).getAll();

  void refresh() =>
      state = ref.read(playlistRepositoryProvider).getAll();

  Future<void> create(String name) async {
    await ref.read(playlistRepositoryProvider).createPlaylist(name);
    refresh();
  }

  Future<void> rename(String id, String newName) async {
    await ref.read(playlistRepositoryProvider).renamePlaylist(id, newName);
    refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(playlistRepositoryProvider).deletePlaylist(id);
    refresh();
  }

  Future<void> addVideo(String playlistId, VideoFile video) async {
    await ref
        .read(playlistRepositoryProvider)
        .addVideo(playlistId, video.id);
    refresh();
  }

  Future<void> removeVideo(String playlistId, String videoId) async {
    await ref
        .read(playlistRepositoryProvider)
        .removeVideo(playlistId, videoId);
    refresh();
  }
}

class PlaylistRepository {
  PlaylistRepository(this._prefs);
  final SharedPreferences _prefs;

  List<Playlist> getAll() {
    final raw = _prefs.getString(_kPlaylistsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Playlist.listFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Playlist? getById(String id) =>
      getAll().where((p) => p.id == id).firstOrNull;

  Future<void> _save(List<Playlist> playlists) async {
    await _prefs.setString(_kPlaylistsKey, Playlist.listToJson(playlists));
  }

  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      videoIds: [],
      createdAt: DateTime.now(),
    );
    final all = getAll()..add(playlist);
    await _save(all);
    return playlist;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final all = getAll().map((p) {
      return p.id == id ? p.copyWith(name: newName) : p;
    }).toList();
    await _save(all);
  }

  Future<void> deletePlaylist(String id) async {
    final all = getAll()..removeWhere((p) => p.id == id);
    await _save(all);
  }

  Future<void> addVideo(String playlistId, String videoId) async {
    final all = getAll().map((p) {
      if (p.id != playlistId || p.videoIds.contains(videoId)) return p;
      return p.copyWith(videoIds: [...p.videoIds, videoId]);
    }).toList();
    await _save(all);
  }

  Future<void> removeVideo(String playlistId, String videoId) async {
    final all = getAll().map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(
          videoIds: p.videoIds.where((id) => id != videoId).toList());
    }).toList();
    await _save(all);
  }
}
