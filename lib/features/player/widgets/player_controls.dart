import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/video_file.dart';
import '../controllers/player_controller.dart';
import 'seek_bar.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.controller,
    required this.video,
    required this.onBack,
    required this.onMoreOptions,
    this.onSubtitles,
    this.onVideoInfo,
    this.onPip,
    this.onCast,
    this.castAvailable = false,
  });

  final PlayerController controller;
  final VideoFile video;
  final VoidCallback onBack;
  final VoidCallback onMoreOptions;
  final VoidCallback? onSubtitles;
  final VoidCallback? onVideoInfo;
  final VoidCallback? onPip;
  final VoidCallback? onCast;
  final bool castAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedOpacity(
      opacity: controller.showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !controller.showControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Top gradient — IgnorePointer so taps reach the gesture layer
            Positioned(
              top: 0, left: 0, right: 0,
              height: 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom gradient — IgnorePointer so taps reach the gesture layer
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 180,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(
                video: video,
                controller: controller,
                onBack: onBack,
                onMoreOptions: onMoreOptions,
                onSubtitles: onSubtitles,
                onVideoInfo: onVideoInfo,
                onCast: onCast,
                castAvailable: castAvailable,
              ),
            ),

            // Center play/pause + seek
            Center(child: _CenterControls(controller: controller)),

            // Bottom bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _BottomBar(
                controller: controller,
                accent: colors.accent,
                onPip: onPip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.video,
    required this.controller,
    required this.onBack,
    required this.onMoreOptions,
    this.onSubtitles,
    this.onVideoInfo,
    this.onCast,
    this.castAvailable = false,
  });
  final VideoFile video;
  final PlayerController controller;
  final VoidCallback onBack;
  final VoidCallback onMoreOptions;
  final VoidCallback? onSubtitles;
  final VoidCallback? onVideoInfo;
  final VoidCallback? onCast;
  final bool castAvailable;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: onBack,
            ),
            // Tappable title → Video Info
            Expanded(
              child: GestureDetector(
                onTap: onVideoInfo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title.replaceAll(RegExp(r'\.[^.]+$'), ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Sleep timer badge under title
                    if (controller.sleepTimerRemaining != null)
                      _SleepBadge(remaining: controller.sleepTimerRemaining!)
                    else if (controller.sleepOnVideoEnd)
                      const _SleepBadge(label: 'Sleep: end of video'),
                  ],
                ),
              ),
            ),
            // Cast shortcut
            if (castAvailable && onCast != null)
              _ControlButton(
                icon: Icons.cast_rounded,
                onTap: onCast!,
                color: Colors.white70,
              ),
            // Subtitle shortcut
            if (onSubtitles != null)
              _ControlButton(
                icon: controller.currentSubtitle.id == 'no'
                    ? Icons.subtitles_off_outlined
                    : Icons.subtitles_rounded,
                onTap: onSubtitles!,
                color: controller.currentSubtitle.id == 'no'
                    ? Colors.white54
                    : Colors.cyanAccent,
              ),
            // Lock
            _ControlButton(
              icon: controller.isLocked
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              onTap: controller.toggleLock,
              color: controller.isLocked
                  ? Colors.orangeAccent
                  : Colors.white70,
            ),
            _ControlButton(
              icon: Icons.more_vert_rounded,
              onTap: onMoreOptions,
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepBadge extends StatelessWidget {
  const _SleepBadge({this.remaining, this.label});
  final Duration? remaining;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ??
        (() {
          final d = remaining!;
          final m = d.inMinutes;
          final s = d.inSeconds % 60;
          return m > 0 ? 'Sleep: ${m}m ${s}s' : 'Sleep: ${s}s';
        })();
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CenterControls extends StatelessWidget {
  const _CenterControls({required this.controller});
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SeekButton(
          icon: Icons.replay_10_rounded,
          onTap: () => controller.seekBy(-10),
        ),
        const SizedBox(width: 24),
        StreamBuilder<bool>(
          stream: controller.player.stream.playing,
          builder: (_, snap) {
            final playing = snap.data ?? false;
            return GestureDetector(
              onTap: controller.player.playOrPause,
              child: AnimatedContainer(
                duration: 150.ms,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ).animate(key: ValueKey(playing)).scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 150.ms,
                    curve: Curves.easeOut,
                  ),
            );
          },
        ),
        const SizedBox(width: 24),
        _SeekButton(
          icon: Icons.forward_10_rounded,
          onTap: () => controller.seekBy(10),
        ),
      ],
    );
  }
}

class _SeekButton extends StatelessWidget {
  const _SeekButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.accent,
    this.onPip,
  });
  final PlayerController controller;
  final Color accent;
  final VoidCallback? onPip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SeekBar(player: controller.player, accent: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
            child: Row(
              children: [
                _SpeedButton(controller: controller),
                const SizedBox(width: 4),
                _LoopButton(controller: controller),
                const SizedBox(width: 4),
                _OrientationLockButton(controller: controller),
                const SizedBox(width: 4),
                _AbRepeatButton(controller: controller),
                const Spacer(),
                if (onPip != null)
                  _ControlButton(
                    icon: Icons.picture_in_picture_alt_rounded,
                    onTap: onPip!,
                    color: Colors.white70,
                  ),
                const SizedBox(width: 4),
                _ZoomButton(controller: controller),
                const SizedBox(width: 4),
                _ControlButton(
                  icon: controller.isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  onTap: controller.toggleFullscreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopButton extends StatelessWidget {
  const _LoopButton({required this.controller});
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final isLooping = controller.loopMode == LoopMode.loopOne;
    return GestureDetector(
      onTap: controller.toggleLoop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isLooping
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLooping
                ? Colors.cyanAccent.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          Icons.repeat_one_rounded,
          size: 18,
          color: isLooping ? Colors.cyanAccent : Colors.white54,
        ),
      ),
    );
  }
}

class _AbRepeatButton extends StatelessWidget {
  const _AbRepeatButton({required this.controller});
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final hasA = controller.abPointA != null;
    final hasB = controller.abPointB != null;
    final active = hasA || hasB;
    final label = hasB ? 'A-B' : (hasA ? 'A-?' : 'A-B');
    final color = hasB
        ? Colors.cyanAccent
        : (hasA ? Colors.orangeAccent : Colors.white54);

    return GestureDetector(
      onTap: controller.cycleAbRepeat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.6) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _OrientationLockButton extends StatelessWidget {
  const _OrientationLockButton({required this.controller});
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final locked = controller.orientationLocked;
    return GestureDetector(
      onTap: () => controller
          .toggleOrientationLock(MediaQuery.of(context).orientation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: locked
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: locked
                ? Colors.cyanAccent.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          locked
              ? Icons.screen_lock_rotation_rounded
              : Icons.screen_rotation_rounded,
          size: 18,
          color: locked ? Colors.cyanAccent : Colors.white54,
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.controller});
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSpeedSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${controller.playbackSpeed}×',
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showSpeedSheet(BuildContext context) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              )),
          const SizedBox(height: 12),
          const Text('Playback Speed',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: speeds.map((s) {
              final selected = controller.playbackSpeed == s;
              return GestureDetector(
                onTap: () {
                  controller.setPlaybackSpeed(s);
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.colors.accent
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? context.colors.accent
                          : Colors.white24,
                    ),
                  ),
                  child: Text('$s×',
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.controller});
  final PlayerController controller;

  IconData get _icon {
    switch (controller.zoomMode) {
      case ZoomMode.fit:
        return Icons.fit_screen_rounded;
      case ZoomMode.fill:
        return Icons.crop_free_rounded;
      case ZoomMode.crop:
        return Icons.crop_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ControlButton(
      icon: _icon,
      onTap: () {
        final modes = ZoomMode.values;
        final nextIdx =
            (modes.indexOf(controller.zoomMode) + 1) % modes.length;
        controller.setZoomMode(modes[nextIdx]);
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}
