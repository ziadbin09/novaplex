import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/download_task.dart';
import '../services/storage_channel.dart';
import 'settings_repository.dart';

const _kDownloadsKey = 'downloads_v1';

final downloadsProvider =
    NotifierProvider<DownloadManager, List<DownloadTask>>(DownloadManager.new);

class DownloadManager extends Notifier<List<DownloadTask>> {
  final _subs = <String, StreamSubscription<List<int>>>{};
  final _httpClients = <String, HttpClient>{};
  // Last persisted/emitted progress per task to throttle updates.
  final _lastEmit = <String, double>{};

  @override
  List<DownloadTask> build() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString(_kDownloadsKey);
    var tasks = <DownloadTask>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        tasks = DownloadTask.listFromJson(raw);
      } catch (_) {}
    }
    // A download in progress can't survive an app restart — mark as paused so
    // the user can resume (HTTP Range continues from the partial file).
    tasks = tasks
        .map((t) => t.status == DownloadStatus.downloading
            ? t.copyWith(status: DownloadStatus.paused)
            : t)
        .toList();
    ref.onDispose(() {
      for (final s in _subs.values) {
        s.cancel();
      }
      for (final c in _httpClients.values) {
        c.close(force: true);
      }
    });
    return tasks;
  }

  void _persist() {
    ref.read(sharedPrefsProvider).setString(
          _kDownloadsKey,
          DownloadTask.listToJson(state),
        );
  }

  void _update(String id, DownloadTask Function(DownloadTask) fn) {
    state = [
      for (final t in state)
        if (t.id == id) fn(t) else t,
    ];
  }

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

  Future<Directory> _downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'downloads'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Queue a new download and start it immediately.
  Future<void> enqueue(String url, String title) async {
    final dir = await _downloadsDir();
    final uri = Uri.parse(url);
    var ext = p.extension(uri.path);
    if (ext.isEmpty || ext.length > 5) ext = '.mp4';
    final id = 'dl_${DateTime.now().millisecondsSinceEpoch}';
    final safeTitle = _sanitize(title.isEmpty ? id : title);
    // Prefix the unique id so two downloads with the same title never collide
    // on disk (which would corrupt files and confuse resume).
    final filePath = p.join(dir.path, '${id}_$safeTitle$ext');

    final task = DownloadTask(
      id: id,
      url: url,
      title: title.isEmpty ? safeTitle : title,
      filePath: filePath,
      createdAt: DateTime.now(),
      status: DownloadStatus.queued,
    );
    state = [task, ...state];
    _persist();
    await _start(task);
  }

  Future<void> _start(DownloadTask task) async {
    final file = File(task.filePath);
    var startByte = 0;
    if (await file.exists()) {
      startByte = await file.length();
    }

    final client = HttpClient();
    _httpClients[task.id] = client;
    try {
      final request = await client.getUrl(Uri.parse(task.url));
      if (startByte > 0) {
        request.headers.add(HttpHeaders.rangeHeader, 'bytes=$startByte-');
      }
      final response = await request.close();

      // 206 = partial content (resume worked); 200 = full restart.
      final resuming = response.statusCode == HttpStatus.partialContent;
      if (!resuming && startByte > 0) {
        // Server ignored Range — start over.
        startByte = 0;
        if (await file.exists()) await file.delete();
      }
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.partialContent) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final contentLen = response.contentLength;
      final total = contentLen > 0 ? startByte + contentLen : 0;
      var received = startByte;

      _update(
        task.id,
        (t) => t.copyWith(
          status: DownloadStatus.downloading,
          totalBytes: total,
          downloadedBytes: received,
        ),
      );
      _persist();

      final sink = file.openWrite(
          mode: resuming ? FileMode.append : FileMode.write);

      final sub = response.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          final prog = total > 0 ? received / total : 0.0;
          final last = _lastEmit[task.id] ?? -1;
          // Throttle UI updates to ~0.5% steps for smooth but cheap repaints.
          if (prog - last >= 0.005 || total == 0) {
            _lastEmit[task.id] = prog;
            _update(task.id,
                (t) => t.copyWith(downloadedBytes: received, totalBytes: total));
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          _subs.remove(task.id);
          _httpClients.remove(task.id);
          _lastEmit.remove(task.id);
          _update(
            task.id,
            (t) => t.copyWith(
              status: DownloadStatus.completed,
              downloadedBytes: received,
              totalBytes: total > 0 ? total : received,
            ),
          );
          _persist();
          // Playable immediately from the temp file; publish to the public
          // gallery in the background and swap the path when it lands.
          _publishToGallery(task.id);
        },
        onError: (e) async {
          await sink.flush();
          await sink.close();
          _subs.remove(task.id);
          _httpClients.remove(task.id);
          // If the task was paused/cancelled the entry may be gone — guard.
          if (state.any((t) => t.id == task.id)) {
            _update(
              task.id,
              (t) => t.status == DownloadStatus.downloading
                  ? t.copyWith(
                      status: DownloadStatus.failed, error: e.toString())
                  : t,
            );
            _persist();
          }
        },
        cancelOnError: true,
      );
      _subs[task.id] = sub;
    } catch (e) {
      _httpClients.remove(task.id);
      _update(task.id,
          (t) => t.copyWith(status: DownloadStatus.failed, error: e.toString()));
      _persist();
    }
  }

  static const _mimeTypes = {
    '.mp4': 'video/mp4',
    '.m4v': 'video/mp4',
    '.mkv': 'video/x-matroska',
    '.webm': 'video/webm',
    '.mov': 'video/quicktime',
    '.avi': 'video/x-msvideo',
    '.3gp': 'video/3gpp',
    '.ts': 'video/mp2t',
  };

  /// Copy a finished download into the public Movies/Manzar gallery folder,
  /// then point the task at the published URI and remove the temp file.
  Future<void> _publishToGallery(String id) async {
    final task = state.where((t) => t.id == id).firstOrNull;
    if (task == null) return;
    if (task.filePath.startsWith('content://')) return; // already published

    var ext = p.extension(task.filePath);
    if (ext.isEmpty) ext = '.mp4';
    var base = _sanitize(task.title);
    // Titles derived from a URL already include the extension — don't double it.
    if (base.toLowerCase().endsWith(ext.toLowerCase())) {
      base = base.substring(0, base.length - ext.length);
    }
    if (base.isEmpty) base = task.id;
    final displayName = '$base$ext';
    final mime = _mimeTypes[ext.toLowerCase()] ?? 'video/mp4';

    final published = await StorageChannel.saveVideo(
      sourcePath: task.filePath,
      displayName: displayName,
      mimeType: mime,
    );
    if (published == null) return; // keep temp file as a fallback

    final tempPath = task.filePath;
    _update(id, (t) => t.copyWith(filePath: published));
    _persist();
    try {
      final f = File(tempPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> pause(String id) async {
    await _subs[id]?.cancel();
    _subs.remove(id);
    _httpClients[id]?.close(force: true);
    _httpClients.remove(id);
    _update(id, (t) => t.copyWith(status: DownloadStatus.paused));
    _persist();
  }

  Future<void> resume(String id) async {
    final task = state.where((t) => t.id == id).firstOrNull;
    if (task == null) return;
    await _start(task);
  }

  /// Cancel an active/queued/failed download and delete its partial file.
  Future<void> cancel(String id) async {
    await _subs[id]?.cancel();
    _subs.remove(id);
    _httpClients[id]?.close(force: true);
    _httpClients.remove(id);
    _lastEmit.remove(id);
    final task = state.where((t) => t.id == id).firstOrNull;
    if (task != null) {
      if (task.filePath.startsWith('content://')) {
        await StorageChannel.deleteVideo(task.filePath);
      } else {
        final f = File(task.filePath);
        if (await f.exists()) await f.delete();
      }
    }
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  /// Remove a completed download (deletes the file from disk).
  Future<void> delete(String id) => cancel(id);

  /// Retry a failed download.
  Future<void> retry(String id) async {
    final task = state.where((t) => t.id == id).firstOrNull;
    if (task == null) return;
    _update(id, (t) => t.copyWith(status: DownloadStatus.queued, error: ''));
    await _start(task);
  }
}
