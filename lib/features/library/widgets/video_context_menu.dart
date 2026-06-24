import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/video_file.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/services/share_channel.dart';
import '../../../shared/widgets/video_thumb.dart';
import '../../player/widgets/video_info_sheet.dart';
import '../../playlists/widgets/add_to_playlist_sheet.dart';

/// Long-press context menu shown in the library.
/// Provides: Play, Add to Playlist, Video Info, Share, Delete.
void showVideoContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required VideoFile video,
  required VoidCallback onPlay,
}) {
  final colors = context.colors;
  showModalBottomSheet(
    context: context,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _VideoContextMenu(
      video: video,
      ref: ref,
      onPlay: onPlay,
    ),
  );
}

class _VideoContextMenu extends StatelessWidget {
  const _VideoContextMenu({
    required this.video,
    required this.ref,
    required this.onPlay,
  });
  final VideoFile video;
  final WidgetRef ref;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Title chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 48,
                    height: 32,
                    child: VideoThumb(video: video, iconSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    video.title.replaceAll(RegExp(r'\.[^.]+$'), ''),
                    style: context.text.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // Actions
          ListTile(
            leading:
                Icon(Icons.play_arrow_rounded, color: colors.accent),
            title: Text('Play', style: context.text.bodyLarge),
            onTap: () {
              Navigator.of(context).pop();
              onPlay();
            },
          ),
          ListTile(
            leading: Icon(Icons.playlist_add_rounded,
                color: colors.textSecondary),
            title: Text('Add to Playlist', style: context.text.bodyLarge),
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                backgroundColor: colors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                isScrollControlled: true,
                builder: (_) => AddToPlaylistSheet(video: video),
              );
            },
          ),
          ListTile(
            leading:
                Icon(Icons.info_outline_rounded, color: colors.textSecondary),
            title: Text('Video Info', style: context.text.bodyLarge),
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1C1C28),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => VideoInfoSheet(video: video),
              );
            },
          ),
          ListTile(
            leading:
                Icon(Icons.share_outlined, color: colors.textSecondary),
            title: Text('Share', style: context.text.bodyLarge),
            onTap: () async {
              Navigator.of(context).pop();
              try {
                await ShareChannel.shareVideo(video.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            title: Text('Delete',
                style: context.text.bodyLarge
                    ?.copyWith(color: Colors.redAccent)),
            onTap: () => _confirmDelete(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete video?'),
        content: Text(
          'This will permanently delete "${video.title.replaceAll(RegExp(r'\.[^.]+$'), '')}" from your device.',
          style: context.text.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final deleted =
                  await PhotoManager.editor.deleteWithIds([video.id]);
              if (deleted.isNotEmpty) {
                ref.invalidate(videosProvider);
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
