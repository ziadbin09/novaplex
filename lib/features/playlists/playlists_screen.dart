import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/playlist_repository.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Text('Playlists',
                      style: context.text.displayMedium
                          ?.copyWith(color: colors.accent, fontSize: 22)),
                  const Spacer(),
                  IconButton(
                    icon:
                        Icon(Icons.add_rounded, color: colors.textSecondary),
                    onPressed: () => _showCreateSheet(context, ref),
                    tooltip: 'New playlist',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: playlists.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: playlists.length,
                      itemBuilder: (ctx, i) {
                        final pl = playlists[i];
                        return Dismissible(
                          key: ValueKey(pl.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await _confirmDelete(context, pl.name);
                          },
                          onDismissed: (_) {
                            ref
                                .read(playlistsProvider.notifier)
                                .delete(pl.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.playlist_play_rounded,
                                    color: colors.accent),
                              ),
                              title: Text(pl.name,
                                  style: context.text.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${pl.count} ${pl.count == 1 ? "video" : "videos"}',
                                style: context.text.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 12),
                              ),
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: colors.textSecondary),
                              onTap: () => ctx.push(
                                '/playlists/${pl.id}',
                                extra: pl.name,
                              ),
                              onLongPress: () =>
                                  _showRenameSheet(context, ref, pl.id, pl.name),
                            ),
                          ).animate().fadeIn(duration: 150.ms),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Playlist', style: context.text.titleMedium),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Playlist name…',
                filled: true,
                fillColor: colors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                ref.read(playlistsProvider.notifier).create(name);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameSheet(
      BuildContext context, WidgetRef ref, String id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rename Playlist', style: context.text.titleMedium),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                ref.read(playlistsProvider.notifier).rename(id, name);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Playlist'),
            content: Text('Delete "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
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
          Icon(Icons.playlist_add_rounded, size: 72, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text('No playlists yet',
              style: context.text.titleMedium
                  ?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 8),
          Text('Tap + to create your first playlist',
              style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
