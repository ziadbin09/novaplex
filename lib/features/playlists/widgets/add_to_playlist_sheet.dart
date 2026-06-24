import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/video_file.dart';
import '../../../data/repositories/playlist_repository.dart';

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  const AddToPlaylistSheet({super.key, required this.video});
  final VideoFile video;

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  final _nameController = TextEditingController();
  bool _showCreateField = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final colors = context.colors;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Add to Playlist',
                    style: context.text.titleMedium),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add_rounded, color: colors.accent),
                  onPressed: () =>
                      setState(() => _showCreateField = !_showCreateField),
                  tooltip: 'New playlist',
                ),
              ],
            ),
          ),
          if (_showCreateField)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Playlist name…',
                        filled: true,
                        fillColor: colors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _createAndAdd(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _createAndAdd(context),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),
          if (playlists.isEmpty && !_showCreateField)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No playlists yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            ),
          ...playlists.map((pl) {
            final alreadyIn = pl.videoIds.contains(widget.video.id);
            return ListTile(
              leading: Icon(
                alreadyIn
                    ? Icons.check_circle_rounded
                    : Icons.playlist_add_rounded,
                color: alreadyIn ? colors.accent : colors.textSecondary,
              ),
              title: Text(pl.name, style: context.text.bodyLarge),
              trailing: Text(
                '${pl.count} videos',
                style: context.text.bodyMedium
                    ?.copyWith(color: colors.textSecondary, fontSize: 12),
              ),
              onTap: alreadyIn ? null : () => _addToExisting(context, pl.id),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(playlistRepositoryProvider);
    final pl = await repo.createPlaylist(name);
    await repo.addVideo(pl.id, widget.video.id);
    ref.read(playlistsProvider.notifier).refresh();
    if (context.mounted) {
      Navigator.pop(context);
      _showSnack(context, 'Added to "$name"');
    }
  }

  Future<void> _addToExisting(BuildContext context, String id) async {
    await ref.read(playlistRepositoryProvider).addVideo(id, widget.video.id);
    ref.read(playlistsProvider.notifier).refresh();
    final name =
        ref.read(playlistRepositoryProvider).getById(id)?.name ?? 'playlist';
    if (context.mounted) {
      Navigator.pop(context);
      _showSnack(context, 'Added to "$name"');
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: 2.seconds));
  }
}

extension on int {
  Duration get seconds => Duration(seconds: this);
}
