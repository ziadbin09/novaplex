import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/models/video_file.dart';
import '../../data/repositories/settings_repository.dart';
import '../player/controllers/player_controller.dart';

class SharedVideoScreen extends ConsumerStatefulWidget {
  const SharedVideoScreen({super.key, required this.video});
  final VideoFile video;

  @override
  ConsumerState<SharedVideoScreen> createState() => _SharedVideoScreenState();
}

class _SharedVideoScreenState extends ConsumerState<SharedVideoScreen> {
  late PlayerController _controller;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _controller = PlayerController(widget.video, settings.hardwareDecode);
    _scheduleHide();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _goFullscreen() {
    _controller.player.pause();
    context.push('/player', extra: widget.video);
  }

  void _share() {
    final url =
        'https://${AppConstants.appLinksDomain}/watch/${widget.video.id}';
    _showShareSheet(context, url);
  }

  void _showShareSheet(BuildContext context, String url) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ShareSheet(url: url),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleNoExt =
        widget.video.title.replaceAll(RegExp(r'\.[^.]+$'), '');
    final sizeLabel = _formatSize(widget.video.size);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Embedded player ───────────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                onTap: _toggleControls,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Video(
                      controller: _controller.videoController,
                      controls: NoVideoControls,
                    ),
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: _EmbeddedControls(
                          controller: _controller,
                          onBack: () => context.pop(),
                          onFullscreen: _goFullscreen,
                          onPlayPause: () {
                            _controller.player.state.playing
                                ? _controller.player.pause()
                                : _controller.player.play();
                            _scheduleHide();
                          },
                          onSeekBack: () {
                            _controller
                                .seekBy(-AppConstants.defaultSkipSeconds);
                            _scheduleHide();
                          },
                          onSeekForward: () {
                            _controller
                                .seekBy(AppConstants.defaultSkipSeconds);
                            _scheduleHide();
                          },
                          onSeekTo: (pos) {
                            _controller.player.seek(pos);
                            _scheduleHide();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info panel ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleNoExt,
                      style: context.text.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (sizeLabel.isNotEmpty) ...[
                          Icon(Icons.storage_rounded,
                              size: 13, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(sizeLabel, style: context.text.bodyMedium),
                          const SizedBox(width: 10),
                        ],
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_formatDate(widget.video.dateAdded),
                            style: context.text.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: _share,
                          colors: colors,
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.open_in_new_rounded,
                          label: 'Fullscreen',
                          onTap: _goFullscreen,
                          colors: colors,
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.more_horiz_rounded,
                          label: 'More',
                          onTap: () => _showMoreSheet(context),
                          colors: colors,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline_rounded,
                  color: colors.textSecondary),
              title: Text('Video Info', style: context.text.bodyLarge),
              subtitle: Text(
                '${_formatSize(widget.video.size).isNotEmpty ? '${_formatSize(widget.video.size)} · ' : ''}'
                '${widget.video.duration.toHhMmSs()}',
                style: context.text.bodyMedium,
              ),
            ),
            ListTile(
              leading: Icon(Icons.content_copy_rounded,
                  color: colors.textSecondary),
              title: Text('Copy Link', style: context.text.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                final url =
                    'https://${AppConstants.appLinksDomain}/watch/${widget.video.id}';
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Embedded controls — StatefulWidget so it subscribes to player streams ──────

class _EmbeddedControls extends StatefulWidget {
  const _EmbeddedControls({
    required this.controller,
    required this.onBack,
    required this.onFullscreen,
    required this.onPlayPause,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onSeekTo,
  });

  final PlayerController controller;
  final VoidCallback onBack;
  final VoidCallback onFullscreen;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final ValueChanged<Duration> onSeekTo;

  @override
  State<_EmbeddedControls> createState() => _EmbeddedControlsState();
}

class _EmbeddedControlsState extends State<_EmbeddedControls> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _seeking = false;
  double _seekValue = 0.0;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    final player = widget.controller.player;
    _position = player.state.position;
    _duration = player.state.duration;
    _playing = player.state.playing;

    _posSub = player.stream.position.listen((pos) {
      if (mounted && !_seeking) setState(() => _position = pos);
    });
    _durSub = player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _playingSub = player.stream.playing.listen((playing) {
      if (mounted) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) => d.toHhMmSs();

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.75),
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                  onPressed: widget.onBack,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded,
                      color: Colors.white, size: 22),
                  onPressed: widget.onFullscreen,
                ),
              ],
            ),
          ),

          // Center controls
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded,
                      color: Colors.white, size: 32),
                  onPressed: widget.onSeekBack,
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: widget.onPlayPause,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded,
                      color: Colors.white, size: 32),
                  onPressed: widget.onSeekForward,
                ),
              ],
            ),
          ),

          // Bottom seekbar + timestamps
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Text(
                  _fmt(_position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor:
                          Colors.white.withValues(alpha: 0.3),
                      thumbColor: Colors.white,
                      overlayColor:
                          Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _seeking ? _seekValue : _progress,
                      onChangeStart: (_) =>
                          setState(() => _seeking = true),
                      onChanged: (v) =>
                          setState(() => _seekValue = v),
                      onChangeEnd: (v) {
                        setState(() => _seeking = false);
                        widget.onSeekTo(Duration(
                          milliseconds:
                              (v * _duration.inMilliseconds).round(),
                        ));
                      },
                    ),
                  ),
                ),
                Text(
                  _fmt(_duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Share sheet (in-app, avoids ChooserActivity crash on BlueStacks) ─────────

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Share video link', style: context.text.titleMedium),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              url,
              style: context.text.bodyMedium?.copyWith(color: colors.accent),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Link'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accent,
                    side: BorderSide(color: colors.accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  onPressed: () {
                    Navigator.pop(context);
                    try {
                      Share.share(url, subject: 'Watch on Manzar');
                    } catch (_) {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Link copied to clipboard')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColorExtension colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: context.text.bodyLarge),
          ],
        ),
      ),
    );
  }
}
