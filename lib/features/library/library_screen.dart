import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../../core/utils/nav_debounce.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/services/intent_channel.dart';
import '../../data/repositories/watch_history_repository.dart';
import '../../data/models/video_file.dart';
import '../../shared/widgets/video_card.dart';
import '../../shared/widgets/video_thumb.dart';
import 'widgets/continue_watching_row.dart';
import 'widgets/play_url_dialog.dart';
import 'widgets/video_context_menu.dart';

enum SortMode { dateDesc, dateAsc, nameAsc, nameDesc, sizeDesc, durationDesc }

class _SortNotifier extends Notifier<SortMode> {
  @override SortMode build() => SortMode.dateDesc;
  void set(SortMode v) => state = v;
}
class _SearchNotifier extends Notifier<String> {
  @override String build() => '';
  void set(String v) => state = v;
}
class _GridNotifier extends Notifier<bool> {
  @override bool build() => true;
  void toggle() => state = !state;
}

final _sortModeProvider = NotifierProvider<_SortNotifier, SortMode>(_SortNotifier.new);
final _searchQueryProvider = NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);
final _isGridProvider = NotifierProvider<_GridNotifier, bool>(_GridNotifier.new);

final _filteredVideosProvider = Provider<AsyncValue<List<VideoFile>>>((ref) {
  final videosAsync = ref.watch(visibleVideosProvider);
  final sort = ref.watch(_sortModeProvider);
  final query = ref.watch(_searchQueryProvider).toLowerCase();
  return videosAsync.whenData((videos) {
    var filtered = query.isEmpty
        ? [...videos]
        : videos.where((v) => v.title.toLowerCase().contains(query)).toList();
    switch (sort) {
      case SortMode.dateDesc:
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case SortMode.dateAsc:
        filtered.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
      case SortMode.nameAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
      case SortMode.nameDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
      case SortMode.sizeDesc:
        filtered.sort((a, b) => b.size.compareTo(a.size));
      case SortMode.durationDesc:
        filtered.sort((a, b) => b.duration.compareTo(a.duration));
    }
    return filtered;
  });
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh library when user returns from Android Settings after granting permission
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(videosProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isGrid = ref.watch(_isGridProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: colors.accentSecondary,
        tooltip: 'Open…',
        onPressed: () => _showOpenSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(isGrid: isGrid, ref: ref),
            _SearchBar(ref: ref),
            _SortBar(ref: ref),
            const ContinueWatchingRow(),
            Expanded(child: _VideoList(isGrid: isGrid)),
          ],
        ),
      ),
    );
  }
}

void _showOpenSheet(BuildContext context) {
  final colors = context.colors;
  showModalBottomSheet(
    context: context,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.link_rounded, color: colors.accent),
            title: Text('Play from URL', style: context.text.bodyLarge),
            subtitle: Text('Stream http(s), rtmp or rtsp',
                style: context.text.bodyMedium?.copyWith(fontSize: 12)),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final url = await showPlayUrlDialog(context);
              if (url != null && context.mounted && NavDebounce.allow()) {
                context.push('/player', extra: _externalVideo(url, url));
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.folder_open_rounded, color: colors.accent),
            title: Text('Open file', style: context.text.bodyLarge),
            subtitle: Text('Browse files not shown in the library',
                style: context.text.bodyMedium?.copyWith(fontSize: 12)),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final uri = await IntentChannel.pickVideo();
              if (uri != null && context.mounted && NavDebounce.allow()) {
                final name = Uri.decodeComponent(uri)
                    .split(RegExp(r'[/:]'))
                    .last;
                context.push('/player',
                    extra: _externalVideo(
                        uri, name.isEmpty ? 'External video' : name));
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

VideoFile _externalVideo(String path, String title) => VideoFile(
      id: 'ext_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      path: path,
      duration: Duration.zero,
      size: 0,
      dateAdded: DateTime.now(),
      mimeType: 'video/*',
    );

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isGrid, required this.ref});
  final bool isGrid;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Text('Manzar',
              style: context.text.displayMedium
                  ?.copyWith(color: colors.accent, fontSize: 22)),
          const Spacer(),
          IconButton(
            icon: Icon(
              isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: colors.textSecondary,
            ),
            onPressed: () =>
                ref.read(_isGridProvider.notifier).toggle(),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
            tooltip: 'Rescan videos',
            onPressed: () => ref.invalidate(videosProvider),
          ),
          IconButton(
            icon: Icon(Icons.sort_rounded, color: colors.textSecondary),
            onPressed: () => _showSortSheet(context, ref),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(_sortModeProvider);
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SortSheet(current: current, onSelect: (s) {
        ref.read(_sortModeProvider.notifier).set(s);
        Navigator.pop(context);
      }),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelect});
  final SortMode current;
  final void Function(SortMode) onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final options = [
      (SortMode.dateDesc, Icons.calendar_today_outlined, 'Newest first'),
      (SortMode.dateAsc, Icons.calendar_today, 'Oldest first'),
      (SortMode.nameAsc, Icons.sort_by_alpha, 'Name A-Z'),
      (SortMode.nameDesc, Icons.sort_by_alpha, 'Name Z-A'),
      (SortMode.sizeDesc, Icons.data_usage, 'Largest first'),
      (SortMode.durationDesc, Icons.access_time, 'Longest first'),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Sort by', style: context.text.titleMedium),
            ),
            const SizedBox(height: 8),
            ...options.map((o) {
              final isSelected = o.$1 == current;
              return ListTile(
                leading: Icon(o.$2,
                    color: isSelected ? colors.accent : colors.textSecondary),
                title: Text(o.$3,
                    style: context.text.bodyLarge?.copyWith(
                      color: isSelected ? colors.accent : colors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    )),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: colors.accent)
                    : null,
                onTap: () => onSelect(o.$1),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        onChanged: (v) => ref.read(_searchQueryProvider.notifier).set(v),
        style: context.text.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search videos…',
          hintStyle: context.text.bodyLarge
              ?.copyWith(color: colors.textSecondary),
          prefixIcon:
              Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
          filled: true,
          fillColor: colors.surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SortBar extends ConsumerWidget {
  const _SortBar({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final colors = context.colors;
    final sort = ref.watch(_sortModeProvider);
    final labels = {
      SortMode.dateDesc: 'Newest',
      SortMode.dateAsc: 'Oldest',
      SortMode.nameAsc: 'A-Z',
      SortMode.nameDesc: 'Z-A',
      SortMode.sizeDesc: 'Largest',
      SortMode.durationDesc: 'Longest',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 14, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(labels[sort] ?? '',
              style: context.text.bodyMedium
                  ?.copyWith(color: colors.accent, fontSize: 12)),
          const Spacer(),
          _videosCount(context, ref),
        ],
      ),
    );
  }

  Widget _videosCount(BuildContext context, WidgetRef ref) {
    return ref.watch(_filteredVideosProvider).when(
      data: (v) => Text('${v.length} videos',
          style: context.text.bodyMedium?.copyWith(fontSize: 12)),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _VideoList extends ConsumerWidget {
  const _VideoList({required this.isGrid});
  final bool isGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_filteredVideosProvider);
    final watchHistory = ref.watch(watchHistoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        if (e is MediaPermissionException) {
          return _PermissionPrompt(
            onGrant: () async {
              final repo = ref.read(mediaRepositoryProvider);
              final granted = await repo.ensureAccess();
              if (granted) {
                ref.invalidate(videosProvider);
              } else {
                await repo.openSettings();
              }
            },
          );
        }
        return Center(
          child: Text('Error: $e', style: context.text.bodyMedium),
        );
      },
      data: (videos) {
        if (videos.isEmpty) return _EmptyState();
        if (isGrid) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: videos.length,
            itemBuilder: (_, i) {
              final v = videos[i];
              final entry = watchHistory
                  .where((e) => e.videoId == v.id)
                  .firstOrNull;
              return VideoCard(
                video: v,
                watchPercent: entry?.watchPercent ?? 0,
                onTap: () {
                  if (NavDebounce.allow()) {
                    context.push('/player', extra: v);
                  }
                },
                onLongPress: () => showVideoContextMenu(
                  context: context,
                  ref: ref,
                  video: v,
                  onPlay: () {
                    if (NavDebounce.allow()) {
                      context.push('/player', extra: v);
                    }
                  },
                ),
              );
            },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          itemCount: videos.length,
          itemBuilder: (_, i) {
            final v = videos[i];
            return _ListTile(
              video: v,
              onTap: () {
                if (NavDebounce.allow()) {
                  context.push('/player', extra: v);
                }
              },
              onLongPress: () => showVideoContextMenu(
                context: context,
                ref: ref,
                video: v,
                onPlay: () {
                  if (NavDebounce.allow()) {
                    context.push('/player', extra: v);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.video, required this.onTap, this.onLongPress});
  final VideoFile video;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
                child: VideoThumb(video: video, iconSize: 24),
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
                          style: context.text.bodyMedium?.copyWith(fontSize: 11)),
                      if (video.resolutionLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(video.resolutionLabel,
                            style: context.text.bodyMedium
                                ?.copyWith(fontSize: 11, color: colors.accent)),
                      ],
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
    ).animate().fadeIn(duration: 150.ms);
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
              size: 72, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text('No videos found',
              style: context.text.titleMedium
                  ?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 8),
          Text('Add videos to your device storage',
              style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({required this.onGrant});
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.perm_media_outlined,
                size: 72, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text('Allow access to your videos',
                textAlign: TextAlign.center,
                style: context.text.titleMedium
                    ?.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Manzar needs permission to show the videos on your device. '
              'Without it, the library stays empty.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onGrant,
              style: FilledButton.styleFrom(backgroundColor: colors.accentSecondary),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text('Grant access'),
            ),
          ],
        ),
      ),
    );
  }
}
