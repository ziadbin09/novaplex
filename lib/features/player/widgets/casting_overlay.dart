import 'package:flutter/material.dart';
import '../../../core/utils/duration_formatter.dart';

/// Full-screen overlay shown while the video is playing on a Cast device.
/// Acts as a simple remote: play/pause, ±10s, and stop casting.
class CastingOverlay extends StatelessWidget {
  const CastingOverlay({
    super.key,
    required this.title,
    required this.isPlaying,
    required this.position,
    required this.onPlayPause,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onStop,
    required this.accent,
  });

  final String title;
  final bool isPlaying;
  final Duration position;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onStop;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.92),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const Spacer(),
              Icon(Icons.cast_connected_rounded, color: accent, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Casting to your device',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                position.toHhMmSs(),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(
                    icon: Icons.replay_10_rounded,
                    onTap: onSeekBack,
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: onPlayPause,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _RoundButton(
                    icon: Icons.forward_10_rounded,
                    onTap: onSeekForward,
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: TextButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.cast_rounded, size: 18),
                  label: const Text('Stop casting'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
