import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../controllers/player_controller.dart';

/// Live playback statistics panel (codec, fps, bitrate, dropped frames).
/// Polls mpv properties once per second while visible.
class StatsOverlay extends StatefulWidget {
  const StatsOverlay({super.key, required this.controller});
  final PlayerController controller;

  @override
  State<StatsOverlay> createState() => _StatsOverlayState();
}

class _StatsOverlayState extends State<StatsOverlay> {
  Timer? _timer;
  Map<String, String> _stats = {};

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final platform = widget.controller.player.platform;
    if (platform is! NativePlayer) return;

    Future<String> prop(String name) async {
      try {
        final v = await platform.getProperty(name);
        return v.isEmpty ? '—' : v;
      } catch (_) {
        return '—';
      }
    }

    final codec = await prop('video-codec');
    final fps = await prop('estimated-vf-fps');
    final containerFps = await prop('container-fps');
    final dropped = await prop('frame-drop-count');
    final bitrate = await prop('video-bitrate');
    final hwdec = await prop('hwdec-current');

    String fmtFps(String v) {
      final d = double.tryParse(v);
      return d == null ? v : d.toStringAsFixed(1);
    }

    String fmtBitrate(String v) {
      final d = double.tryParse(v);
      if (d == null) return v;
      return '${(d / 1000000).toStringAsFixed(1)} Mbps';
    }

    final w = widget.controller.player.state.width ?? 0;
    final h = widget.controller.player.state.height ?? 0;

    if (!mounted) return;
    setState(() {
      _stats = {
        'Codec': codec,
        'Resolution': w > 0 ? '$w × $h' : '—',
        'FPS': '${fmtFps(fps)} / ${fmtFps(containerFps)}',
        'Bitrate': fmtBitrate(bitrate),
        'Dropped': dropped,
        'HW decode': hwdec == '—' || hwdec == 'no' ? 'off' : hwdec,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 90,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded,
                    color: Colors.cyanAccent, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'STATS',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: widget.controller.toggleStats,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._stats.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ),
                    Text(
                      e.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
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
}
