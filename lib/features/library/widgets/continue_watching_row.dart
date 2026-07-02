import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../data/models/watch_entry.dart';
import '../../../data/models/video_file.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/watch_history_repository.dart';
import '../../../shared/widgets/video_thumb.dart';

class ContinueWatchingRow extends ConsumerWidget {
  const ContinueWatchingRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);
    final videosAsync = ref.watch(videosProvider);

    if (history.isEmpty) return const SizedBox.shrink();

    // Filter to in-progress (not finished) entries
    final inProgress = history.where((e) => !e.isFinished && e.positionMs > 5000).toList();
    if (inProgress.isEmpty) return const SizedBox.shrink();

    return videosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (videos) {
        // Match history entries to VideoFile objects
        final items = inProgress
            .map((e) => (
                  entry: e,
                  video: videos.where((v) => v.id == e.videoId).firstOrNull,
                ))
            .where((p) => p.video != null)
            .toList();

        if (items.isEmpty) return const SizedBox.shrink();

        final colors = context.colors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 16, color: colors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Continue Watching',
                    style: context.text.titleSmall
                        ?.copyWith(color: colors.textPrimary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _clearAll(ref),
                    child: Text(
                      'Clear',
                      style: context.text.bodyMedium
                          ?.copyWith(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) => _ContinueCard(
                  entry: items[i].entry,
                  video: items[i].video!,
                  onTap: () {
                    if (NavDebounce.allow()) {
                      ctx.push('/player', extra: items[i].video);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  void _clearAll(WidgetRef ref) {
    ref.read(watchHistoryRepositoryProvider).clearAll().then((_) {
      ref.read(watchHistoryProvider.notifier).refresh();
    });
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.entry,
    required this.video,
    required this.onTap,
  });
  final WatchEntry entry;
  final VideoFile video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = Duration(
      milliseconds: (entry.durationMs - entry.positionMs).clamp(0, entry.durationMs),
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail + progress
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumb(video: video),
                    // Scrim
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                    // Remaining time
                    Positioned(
                      bottom: 14,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${remaining.toHhMmSs()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Play icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    // Progress bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: entry.watchPercent,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(colors.accent),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              video.title.replaceAll(RegExp(r'\.[^.]+$'), ''),
              style: context.text.bodyMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
