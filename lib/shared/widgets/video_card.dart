import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/models/video_file.dart';
import 'video_thumb.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({
    super.key,
    required this.video,
    this.watchPercent = 0,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final VideoFile video;
  final double watchPercent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: 150.ms,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Thumbnail(video: video, watchPercent: watchPercent),
            _Info(video: video),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.video, required this.watchPercent});
  final VideoFile video;
  final double watchPercent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            VideoThumb(video: video),

            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Duration badge
            Positioned(
              bottom: watchPercent > 0 ? 10 : 6,
              right: 6,
              child: _Badge(
                  label: video.duration.toHhMmSs(), icon: Icons.access_time),
            ),

            // Resolution badge
            if (video.resolutionLabel.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: _Badge(label: video.resolutionLabel),
              ),

            // Progress bar
            if (watchPercent > 0 && watchPercent < 0.95)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: watchPercent,
                  backgroundColor: Colors.white24,
                  valueColor:
                      AlwaysStoppedAnimation(colors.accent),
                  minHeight: 3,
                ),
              ),

            // Selected overlay
            if (true == false) // placeholder for selection state
              Container(color: colors.accent.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.white70),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.video});
  final VideoFile video;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title.replaceAll(RegExp(r'\.[^.]+$'), ''),
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            video.size.toReadableSize(),
            style: textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
