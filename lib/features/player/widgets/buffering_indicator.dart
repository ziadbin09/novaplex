import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../core/theme/app_theme.dart';

/// Shows a centered spinner whenever the player is buffering — covers both
/// the initial load (blank video surface before the first frame) and any
/// mid-playback network stalls.
class BufferingIndicator extends StatefulWidget {
  const BufferingIndicator({super.key, required this.player});
  final Player player;

  @override
  State<BufferingIndicator> createState() => _BufferingIndicatorState();
}

class _BufferingIndicatorState extends State<BufferingIndicator> {
  late bool _buffering = widget.player.state.buffering;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.stream.buffering.listen((b) {
      if (mounted) setState(() => _buffering = b);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _buffering ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                  colors.accentSecondary ?? colors.accent),
            ),
          ),
        ),
      ),
    );
  }
}
