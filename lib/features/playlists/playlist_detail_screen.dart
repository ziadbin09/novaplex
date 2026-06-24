import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/models/video_file.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../data/repositories/watch_history_repository.dart';
import '../../shared/widgets/video_thumb.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  final String playlistId;
  final String playlistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
    final videosAsync = ref.watch(videosProvider);
    final history = ref.watch(watchHistoryProvider);
    final colors = context.colors;

    if (playlist == null) {
      return Scaffold(
        body: Center(
          child: Text('Playlist not found',
              style: context.text.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: colors.textPrimary, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      playlist.name,
                      style: context.text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${playlist.count} videos',
                    style: context.text.bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: videosAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (allVideos) {
                  final videos = playlist.videoIds
                      .map((id) =>
                          allVideos.where((v) => v.id == id).firstOrNull)
                      .whereType<VideoFile>()
                      .toList();

                  if (videos.isEmpty) {
                    return _EmptyState();
                  }

                  return Column(
                    children: [
                      // Play all button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.push('/player', extra: videos.first),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 16),
                          itemCount: videos.length,
                          itemBuilder: (ctx, i) {
                            final v = videos[i];
                            final entry = history
                                .where((e) => e.videoId == v.id)
                                .firstOrNull;
                            return _PlaylistTile(
                              video: v,
                              watchPercent: entry?.watchPercent ?? 0,
                              onTap: () =>
                                  ctx.push('/player', extra: v),
                              onRemove: () => ref
                                  .read(playlistsProvider.notifier)
                                  .removeVideo(playlistId, v.id),
                            ).animate().fadeIn(duration: 150.ms);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.video,
    required this.watchPercent,
    required this.onTap,
    required this.onRemove,
  });
  final VideoFile video;
  final double watchPercent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(11)),
            child: SizedBox(
              width: 100,
              height: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumb(video: video, iconSize: 24),
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
                ],
              ),
            ),
          ),
          // Info
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title.replaceAll(RegExp(r'\.[^.]+$'), ''),
                      style: context.text.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      video.duration.toHhMmSs(),
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Remove button
          IconButton(
            icon: Icon(Icons.remove_circle_outline_rounded,
                color: colors.textSecondary, size: 20),
            onPressed: onRemove,
            tooltip: 'Remove from playlist',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined,
              size: 60, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text('No videos in this playlist',
              style: context.text.titleMedium
                  ?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 8),
          Text('Long-press any video to add it here',
              style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
