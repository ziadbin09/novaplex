import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/models/video_file.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/watch_history_repository.dart';
import '../../data/services/pip_channel.dart';
import '../../data/services/media_session_channel.dart';
import '../../data/services/cast_channel.dart';
import '../../data/services/local_media_server.dart';
import 'controllers/player_controller.dart';
import 'widgets/player_controls.dart';
import 'widgets/gesture_detector_layer.dart';
import 'widgets/subtitle_picker_sheet.dart';
import 'widgets/audio_track_picker_sheet.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'widgets/stats_overlay.dart';
import 'widgets/sync_sheet.dart';
import 'widgets/video_info_sheet.dart';
import 'widgets/equalizer_sheet.dart';
import 'widgets/casting_overlay.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.video});
  final VideoFile video;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late PlayerController _controller;
  Timer? _saveTimer;
  StreamSubscription<bool>? _pipSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _completedSub;
  bool _inPipMode = false;

  // Resume prompt
  Duration? _resumePosition;
  Timer? _resumeDismissTimer;

  // Auto-play next
  VideoFile? _upNext;
  int _upNextCountdown = 5;
  Timer? _upNextTimer;

  // Cast
  final LocalMediaServer _mediaServer = LocalMediaServer();
  StreamSubscription<CastEvent>? _castSub;
  bool _castAvailable = false;
  bool _isCasting = false;
  bool _castPlaying = true;
  Duration _castPosition = Duration.zero;
  Timer? _castTicker;

  @override
  void initState() {
    super.initState();
    // Owned directly — an autoDispose provider with no listeners would
    // dispose the controller (and the player) right after creation
    final settings = ref.read(settingsProvider);
    _controller = PlayerController(
      widget.video,
      settings.hardwareDecode,
      eqBands: settings.eqBands,
    );
    _controller.addListener(_rebuild);
    _resumeIfNeeded();
    _startSaveTimer();
    PipChannel.setPlayerActive(true);
    _pipSub = PipChannel.pipModeStream.listen((inPip) {
      if (mounted) setState(() => _inPipMode = inPip);
    });
    _startMediaSession();
    _watchForCompletion();
    _initCast();
  }

  Future<void> _initCast() async {
    final available = await CastChannel.isAvailable();
    if (!mounted) return;
    setState(() => _castAvailable = available);
    if (!available) return;
    _castSub = CastChannel.events.listen(_onCastEvent);
  }

  void _onCastEvent(CastEvent e) {
    if (!mounted) return;
    if (e.connected && !_isCasting) {
      _startCasting();
    } else if (e.disconnected && _isCasting) {
      _stopCasting();
    }
  }

  Future<void> _startCasting() async {
    final pos = _controller.player.state.position;
    _controller.player.pause();

    final path = widget.video.path;
    String? url;
    String contentType = 'video/mp4';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      url = path;
    } else {
      url = await _mediaServer.serve(path);
      contentType = _mediaServer.contentTypeFor(path);
    }

    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start cast (no network)')),
        );
      }
      return;
    }

    final title = widget.video.title.replaceAll(RegExp(r'\.[^.]+$'), '');
    final ok = await CastChannel.loadMedia(
      url: url,
      title: title,
      contentType: contentType,
      position: pos,
    );
    if (!ok) return;

    if (mounted) {
      setState(() {
        _isCasting = true;
        _castPlaying = true;
        _castPosition = pos;
      });
    }
    _startCastTicker();
  }

  void _startCastTicker() {
    _castTicker?.cancel();
    _castTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isCasting || !_castPlaying) return;
      setState(() => _castPosition += const Duration(seconds: 1));
    });
  }

  Future<void> _stopCasting() async {
    _castTicker?.cancel();
    await _mediaServer.stop();
    if (mounted) setState(() => _isCasting = false);
  }

  void _toggleCastPlayback() {
    setState(() => _castPlaying = !_castPlaying);
    if (_castPlaying) {
      CastChannel.play();
    } else {
      CastChannel.pause();
    }
  }

  void _castSeekBy(int seconds) {
    final target = _castPosition + Duration(seconds: seconds);
    final clamped = target.isNegative ? Duration.zero : target;
    setState(() => _castPosition = clamped);
    CastChannel.seek(clamped);
  }

  Future<void> _endCastSession() async {
    await CastChannel.stop();
    await _stopCasting();
  }

  void _watchForCompletion() {
    _completedSub = _controller.player.stream.completed.listen((done) {
      if (done && mounted) _maybeQueueNext();
    });
  }

  void _maybeQueueNext() {
    final settings = ref.read(settingsProvider);
    if (!settings.autoPlayNext) return;
    if (_controller.loopMode != LoopMode.off) return;
    if (_controller.sleepOnVideoEnd || _controller.didSleepAtEnd) return;
    if (_controller.abPointB != null) return;

    final videos = ref.read(videosProvider).value;
    if (videos == null) return;
    final folderVids = videos
        .where((v) => v.folderName == widget.video.folderName)
        .toList();
    final idx = folderVids.indexWhere((v) => v.id == widget.video.id);
    if (idx < 0 || idx + 1 >= folderVids.length) return;

    final next = folderVids[idx + 1];
    setState(() {
      _upNext = next;
      _upNextCountdown = 5;
    });
    _upNextTimer?.cancel();
    _upNextTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _upNextCountdown--);
      if (_upNextCountdown <= 0) {
        t.cancel();
        _playNext(next);
      }
    });
  }

  void _playNext(VideoFile next) {
    _upNextTimer?.cancel();
    if (!mounted) return;
    context.pushReplacement('/player', extra: next);
  }

  void _cancelUpNext() {
    _upNextTimer?.cancel();
    setState(() => _upNext = null);
  }

  Future<void> _startMediaSession() async {
    // Android 13+ requires a runtime grant before the media notification /
    // lock-screen controls can be shown.
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (!mounted) return;
    final title = widget.video.title.replaceAll(RegExp(r'\.[^.]+$'), '');
    MediaSessionChannel.start(title);
    MediaSessionChannel.onPlay = () => _controller.player.play();
    MediaSessionChannel.onPause = () => _controller.player.pause();
    MediaSessionChannel.onSeek = (pos) => _controller.player.seek(pos);
    // Keep notification state in sync with playback
    _playingSub = _controller.player.stream.playing.listen((_) {
      _pushMediaState();
    });
  }

  void _pushMediaState() {
    MediaSessionChannel.update(
      playing: _controller.player.state.playing,
      position: _controller.player.state.position,
      duration: _controller.player.state.duration,
    );
  }

  void _rebuild() => setState(() {});

  Future<void> _resumeIfNeeded() async {
    final repo = ref.read(watchHistoryRepositoryProvider);
    final entry = repo.getEntry(widget.video.id);
    if (entry != null && entry.positionMs > 5000 && !entry.isFinished) {
      // Ask instead of silently jumping
      setState(() {
        _resumePosition = Duration(milliseconds: entry.positionMs);
      });
      _resumeDismissTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _resumePosition = null);
      });
    }
  }

  void _acceptResume() {
    final pos = _resumePosition;
    _resumeDismissTimer?.cancel();
    setState(() => _resumePosition = null);
    if (pos != null) _controller.resumeTo(pos);
  }

  void _declineResume() {
    _resumeDismissTimer?.cancel();
    setState(() => _resumePosition = null);
  }

  void _startSaveTimer() {
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveProgress();
      _pushMediaState();
    });
  }

  Future<void> _saveProgress() async {
    final pos = _controller.player.state.position;
    final dur = _controller.player.state.duration;
    if (dur <= Duration.zero) return;
    await ref.read(watchHistoryRepositoryProvider).saveEntry(
          videoId: widget.video.id,
          videoPath: widget.video.path,
          videoTitle: widget.video.title,
          position: pos,
          duration: dur,
        );
    if (mounted) ref.read(watchHistoryProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveProgress();
    _controller.removeListener(_rebuild);
    _pipSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    _resumeDismissTimer?.cancel();
    _upNextTimer?.cancel();
    _castTicker?.cancel();
    _castSub?.cancel();
    // Local file casting depends on our in-app HTTP server, which dies with
    // this screen — end the session so the TV doesn't stall on a dead URL.
    if (_isCasting) CastChannel.stop();
    _mediaServer.stop();
    PipChannel.setPlayerActive(false);
    MediaSessionChannel.stop();
    _controller.dispose();
    super.dispose();
  }

  BoxFit _boxFit() {
    switch (_controller.zoomMode) {
      case ZoomMode.fit:
        return BoxFit.contain;
      case ZoomMode.fill:
        return BoxFit.fitWidth;
      case ZoomMode.crop:
        return BoxFit.cover;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    final subtitleConfig = SubtitleViewConfiguration(
      style: TextStyle(
        fontSize: settings.subtitleSize * 2,
        color: settings.subtitleColor,
        backgroundColor:
            Colors.black.withValues(alpha: settings.subtitleBgOpacity),
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );

    // In PiP mode show only the video, no controls overlay
    if (_inPipMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Video(
            controller: _controller.videoController,
            fit: _boxFit(),
            controls: NoVideoControls,
            subtitleViewConfiguration: subtitleConfig,
          ),
        ),
      );
    }

    // Layer order matters: video at the bottom, gesture surface in the
    // middle, controls on top so buttons win taps over the gesture layer
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Transform.scale(
              scale: _controller.videoScale,
              child: Center(
                child: Video(
                  controller: _controller.videoController,
                  fit: _boxFit(),
                  controls: NoVideoControls,
                  subtitleViewConfiguration: subtitleConfig,
                ),
              ),
            ),
          ),
          GestureDetectorLayer(
            controller: _controller,
            enableBrightness: settings.brightnessGesture,
            enableVolume: settings.volumeGesture,
            enableSeek: settings.seekGesture,
            skipSeconds: settings.skipDuration,
            child: const SizedBox.expand(),
          ),
          PlayerControls(
            controller: _controller,
            video: widget.video,
            onBack: () => Navigator.of(context).pop(),
            onMoreOptions: () => _showMoreOptions(context),
            onSubtitles: () => _showSubtitlePicker(context),
            onVideoInfo: () => _showVideoInfo(context),
            onPip: () => PipChannel.enterPip(),
            onCast: () => CastChannel.showPicker(),
            castAvailable: _castAvailable,
          ),
          if (_controller.showStats)
            StatsOverlay(controller: _controller),
          if (_resumePosition != null)
            _ResumePrompt(
              position: _resumePosition!,
              onResume: _acceptResume,
              onStartOver: _declineResume,
            ),
          if (_upNext != null)
            _UpNextOverlay(
              next: _upNext!,
              countdown: _upNextCountdown,
              onPlayNow: () => _playNext(_upNext!),
              onCancel: _cancelUpNext,
            ),
          if (_isCasting)
            CastingOverlay(
              title: widget.video.title.replaceAll(RegExp(r'\.[^.]+$'), ''),
              isPlaying: _castPlaying,
              position: _castPosition,
              accent: settings.accentColor,
              onPlayPause: _toggleCastPlayback,
              onSeekBack: () => _castSeekBy(-10),
              onSeekForward: () => _castSeekBy(10),
              onStop: _endCastSession,
            ),
        ],
      ),
    );
  }

  // ── Sheets ───────────────────────────────────────────────────────────────

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoreOptionsSheet(
        controller: _controller,
        video: widget.video,
        onSubtitles: () {
          Navigator.pop(context);
          _showSubtitlePicker(context);
        },
        onAudioTrack: () {
          Navigator.pop(context);
          _showAudioTrackPicker(context);
        },
        onSleepTimer: () {
          Navigator.pop(context);
          _showSleepTimer(context);
        },
        onVideoInfo: () {
          Navigator.pop(context);
          _showVideoInfo(context);
        },
        onScreenshot: () {
          Navigator.pop(context);
          _takeScreenshot(context);
        },
        onEqualizer: () {
          Navigator.pop(context);
          _showEqualizer(context);
        },
        onSync: () {
          Navigator.pop(context);
          _showSyncSheet(context);
        },
      ),
    );
  }

  void _showEqualizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => EqualizerSheet(
        controller: _controller,
        initialBands: ref.read(settingsProvider).eqBands,
        onBandsChanged: (bands) {
          ref.read(settingsProvider.notifier).setEqBands(bands);
        },
      ),
    );
  }

  void _showSyncSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SyncSheet(controller: _controller),
    );
  }

  Future<void> _takeScreenshot(BuildContext context) async {
    try {
      final bytes = await _controller.player.screenshot();
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screenshot failed')),
          );
        }
        return;
      }
      final filename =
          'NovaPlex_${DateTime.now().millisecondsSinceEpoch}.png';
      await PhotoManager.editor.saveImage(
        bytes,
        filename: filename,
        desc: 'Screenshot from NovaPlex',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot saved to gallery')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Screenshot error: $e')),
        );
      }
    }
  }

  void _showSubtitlePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubtitlePickerSheet(
        player: _controller.player,
        videoPath: widget.video.path,
        currentTrack: _controller.currentSubtitle,
      ),
    );
  }

  void _showAudioTrackPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AudioTrackPickerSheet(player: _controller.player),
    );
  }

  void _showSleepTimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SleepTimerSheet(controller: _controller),
    );
  }

  void _showVideoInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VideoInfoSheet(video: widget.video),
    );
  }
}

// ── More Options Sheet ────────────────────────────────────────────────────

class _MoreOptionsSheet extends StatelessWidget {
  const _MoreOptionsSheet({
    required this.controller,
    required this.video,
    required this.onSubtitles,
    required this.onAudioTrack,
    required this.onSleepTimer,
    required this.onVideoInfo,
    required this.onScreenshot,
    required this.onEqualizer,
    required this.onSync,
  });
  final PlayerController controller;
  final VideoFile video;
  final VoidCallback onSubtitles;
  final VoidCallback onAudioTrack;
  final VoidCallback onSleepTimer;
  final VoidCallback onVideoInfo;
  final VoidCallback onScreenshot;
  final VoidCallback onEqualizer;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final subtitleLabel =
        controller.currentSubtitle.id == 'no' ? 'Off' : 'On';
    final audioLabel =
        controller.player.state.tracks.audio.length > 1 ? 'Available' : 'Default';

    final options = [
      (Icons.fit_screen_rounded, 'Video Zoom', _zoomLabel(),
          () => _cycleZoom(context)),
      (Icons.subtitles_outlined, 'Subtitles', subtitleLabel, onSubtitles),
      (Icons.audiotrack_outlined, 'Audio Track', audioLabel, onAudioTrack),
      (Icons.camera_alt_outlined, 'Screenshot', '', onScreenshot),
      (Icons.equalizer_rounded, 'Equalizer', '', onEqualizer),
      (
        Icons.speed_rounded,
        'Playback Stats',
        controller.showStats ? 'On' : 'Off',
        () {
          controller.toggleStats();
          Navigator.pop(context);
        }
      ),
      (Icons.info_outline_rounded, 'Video Info', '', onVideoInfo),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              ...options.map((o) => ListTile(
                    leading: Icon(o.$1, color: Colors.white70),
                    title: Text(o.$2,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15)),
                    trailing: o.$3.isNotEmpty
                        ? Text(o.$3,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13))
                        : null,
                    onTap: o.$4,
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  String _zoomLabel() {
    switch (controller.zoomMode) {
      case ZoomMode.fit:
        return 'Fit';
      case ZoomMode.fill:
        return 'Fill';
      case ZoomMode.crop:
        return 'Crop';
    }
  }

  void _cycleZoom(BuildContext context) {
    final modes = ZoomMode.values;
    final next =
        modes[(modes.indexOf(controller.zoomMode) + 1) % modes.length];
    controller.setZoomMode(next);
    Navigator.pop(context);
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}

// ── Resume prompt overlay ─────────────────────────────────────────────────

class _ResumePrompt extends StatelessWidget {
  const _ResumePrompt({
    required this.position,
    required this.onResume,
    required this.onStartOver,
  });
  final Duration position;
  final VoidCallback onResume;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 110,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xEE1C1C28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Resume from ${position.toHhMmSs()}?',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onStartOver,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                ),
                child: const Text('Start over',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
              FilledButton(
                onPressed: onResume,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Resume',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Up next overlay ───────────────────────────────────────────────────────

class _UpNextOverlay extends StatelessWidget {
  const _UpNextOverlay({
    required this.next,
    required this.countdown,
    required this.onPlayNow,
    required this.onCancel,
  });
  final VideoFile next;
  final int countdown;
  final VoidCallback onPlayNow;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 110,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xEE1C1C28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Up next in $countdown…',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              next.title.replaceAll(RegExp(r'\.[^.]+$'), ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPlayNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 34),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Play now',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
