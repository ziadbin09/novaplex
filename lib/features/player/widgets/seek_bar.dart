import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../core/utils/duration_formatter.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.player,
    required this.accent,
  });
  final Player player;
  final Color accent;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (_, posSnap) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          builder: (_, durSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = durSnap.data ?? Duration.zero;
            final total = duration.inMilliseconds.toDouble();
            final current = _dragging
                ? _dragValue
                : position.inMilliseconds.toDouble();
            final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: widget.accent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: widget.accent,
                    overlayColor: widget.accent.withValues(alpha: 0.2),
                    trackHeight: 3.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: progress,
                    onChangeStart: (_) {
                      setState(() {
                        _dragging = true;
                        _dragValue = current;
                      });
                    },
                    onChanged: (v) {
                      setState(() => _dragValue = v * total);
                    },
                    onChangeEnd: (v) {
                      final target =
                          Duration(milliseconds: (v * total).round());
                      widget.player.seek(target);
                      setState(() => _dragging = false);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Duration(milliseconds: current.round()).toHhMmSs(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        duration.toHhMmSs(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
