import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/models/video_file.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/watch_history_repository.dart';
import '../../shared/widgets/video_thumb.dart';
import 'widgets/video_context_menu.dart';

class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({super.key, required this.folderName});
  final String folderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final foldersAsync = ref.watch(videosByFolderProvider);
    final watchHistory = ref.watch(watchHistoryProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(folderName, style: context.text.titleMedium),
      ),
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error loading folder', style: context.text.bodyMedium)),
        data: (folders) {
          final videos = folders[folderName] ?? [];
          if (videos.isEmpty) {
            return Center(
              child: Text('No videos in this folder',
                  style: context.text.bodyMedium),
            );
          }
          return Column(
            children: [
              // Header: count + Play All
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Text('${videos.length} videos',
                        style: context.text.bodyMedium),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accentSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Play All'),
                      onPressed: () =>
                          context.push('/player', extra: videos.first),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: videos.length,
                  itemBuilder: (_, i) {
                    final v = videos[i];
                    final entry = watchHistory
                        .where((e) => e.videoId == v.id)
                        .firstOrNull;
                    return _FolderVideoTile(
                      video: v,
                      watchPercent: entry?.watchPercent ?? 0,
                      onTap: () => context.push('/player', extra: v),
                      onLongPress: () => showVideoContextMenu(
                        context: context,
                        ref: ref,
                        video: v,
                        onPlay: () => context.push('/player', extra: v),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FolderVideoTile extends StatelessWidget {
  const _FolderVideoTile({
    required this.video,
    required this.watchPercent,
    required this.onTap,
    required this.onLongPress,
  });
  final VideoFile video;
  final double watchPercent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumb(video: video, iconSize: 24),
                    if (watchPercent > 0)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearProgressIndicator(
                          value: watchPercent,
                          minHeight: 3,
                          backgroundColor: Colors.black45,
                          valueColor:
                              AlwaysStoppedAnimation(colors.accent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(video.duration.toHhMmSs(),
                          style: context.text.labelSmall),
                      const SizedBox(width: 8),
                      Text(video.size.toReadableSize(),
                          style: context.text.bodyMedium
                              ?.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline,
                color: colors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
