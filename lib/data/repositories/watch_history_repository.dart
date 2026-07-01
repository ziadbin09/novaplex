import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watch_entry.dart';
import 'settings_repository.dart';

const _kWatchHistoryKey = 'watch_history_v1';
const _kMaxEntries = 30;

final watchHistoryRepositoryProvider =
    Provider<WatchHistoryRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return WatchHistoryRepository(prefs);
});

/// Exposes the watch history list as an AsyncNotifier so the UI can watch it.
final watchHistoryProvider =
    NotifierProvider<WatchHistoryNotifier, List<WatchEntry>>(
        WatchHistoryNotifier.new);

class WatchHistoryNotifier extends Notifier<List<WatchEntry>> {
  @override
  List<WatchEntry> build() {
    final repo = ref.watch(watchHistoryRepositoryProvider);
    return repo.getAll();
  }

  void refresh() => state = ref.read(watchHistoryRepositoryProvider).getAll();
}

class WatchHistoryRepository {
  WatchHistoryRepository(this._prefs);
  final SharedPreferences _prefs;

  List<WatchEntry>? _cache;

  List<WatchEntry> getAll() {
    if (_cache != null) return List.unmodifiable(_cache!);
    final raw = _prefs.getString(_kWatchHistoryKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return const [];
    }
    try {
      _cache = WatchEntry.listFromJson(raw);
    } catch (_) {
      _cache = [];
    }
    return List.unmodifiable(_cache!);
  }

  WatchEntry? getEntry(String videoId) {
    return getAll().where((e) => e.videoId == videoId).firstOrNull;
  }

  Future<void> saveEntry({
    required String videoId,
    required String videoPath,
    required String videoTitle,
    required Duration position,
    required Duration duration,
  }) async {
    final entries = List<WatchEntry>.from(getAll());
    entries.removeWhere((e) => e.videoId == videoId);
    entries.insert(
      0,
      WatchEntry(
        videoId: videoId,
        videoPath: videoPath,
        videoTitle: videoTitle,
        positionMs: position.inMilliseconds,
        durationMs: duration.inMilliseconds,
        lastWatched: DateTime.now(),
      ),
    );
    final trimmed =
        entries.length > _kMaxEntries ? entries.sublist(0, _kMaxEntries) : entries;
    _cache = trimmed;
    await _prefs.setString(_kWatchHistoryKey, WatchEntry.listToJson(trimmed));
  }

  Future<void> removeEntry(String videoId) async {
    final entries = List<WatchEntry>.from(getAll())
      ..removeWhere((e) => e.videoId == videoId);
    _cache = entries;
    await _prefs.setString(_kWatchHistoryKey, WatchEntry.listToJson(entries));
  }

  Future<void> clearAll() async {
    _cache = [];
    await _prefs.remove(_kWatchHistoryKey);
  }
}
