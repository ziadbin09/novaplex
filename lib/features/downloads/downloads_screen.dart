import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/models/download_task.dart';
import '../../data/models/video_file.dart';
import '../../data/repositories/download_repository.dart';
import 'widgets/download_url_dialog.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tasks = ref.watch(downloadsProvider);
    final active = tasks.where((t) => !t.isComplete).toList();
    final completed = tasks.where((t) => t.isComplete).toList();

    return Scaffold(
      backgroundColor: colors.bg,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: colors.accentSecondary,
        tooltip: 'Download from URL',
        onPressed: () => _showDownloadDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text('Downloads',
                      style: context.text.displayMedium
                          ?.copyWith(color: colors.accent, fontSize: 22)),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      children: [
                        if (active.isNotEmpty) ...[
                          _SectionLabel('In progress'),
                          ...active.map((t) =>
                              _ActiveTile(task: t, ref: ref)),
                        ],
                        if (completed.isNotEmpty) ...[
                          _SectionLabel('Downloaded'),
                          ...completed.map((t) =>
                              _CompletedTile(task: t, ref: ref)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDownloadDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDownloadUrlDialog(context);
    if (result == null) return;
    await ref
        .read(downloadsProvider.notifier)
        .enqueue(result.url, result.title);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        text.toUpperCase(),
        style: context.text.bodyMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: context.colors.accent,
        ),
      ),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({required this.task, required this.ref});
  final DownloadTask task;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notifier = ref.read(downloadsProvider.notifier);
    final pct = (task.progress * 100).toStringAsFixed(0);
    final downloaded = task.downloadedBytes.toReadableSize();
    final total = task.totalBytes > 0 ? task.totalBytes.toReadableSize() : '—';

    IconData statusIcon;
    Color statusColor;
    switch (task.status) {
      case DownloadStatus.downloading:
        statusIcon = Icons.pause_rounded;
        statusColor = colors.accent;
      case DownloadStatus.paused:
        statusIcon = Icons.play_arrow_rounded;
        statusColor = colors.accent;
      case DownloadStatus.failed:
        statusIcon = Icons.refresh_rounded;
        statusColor = Colors.orangeAccent;
      default:
        statusIcon = Icons.hourglass_empty_rounded;
        statusColor = colors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: context.text.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(statusIcon, color: statusColor, size: 22),
                onPressed: () {
                  switch (task.status) {
                    case DownloadStatus.downloading:
                      notifier.pause(task.id);
                    case DownloadStatus.paused:
                      notifier.resume(task.id);
                    case DownloadStatus.failed:
                      notifier.retry(task.id);
                    default:
                      break;
                  }
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    color: colors.textSecondary, size: 20),
                onPressed: () => notifier.cancel(task.id),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.totalBytes > 0 ? task.progress : null,
              minHeight: 5,
              backgroundColor: colors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(
                task.status == DownloadStatus.failed
                    ? Colors.orangeAccent
                    : colors.accent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task.status == DownloadStatus.failed
                ? 'Failed${task.error != null ? " · ${task.error}" : ""}'
                : task.status == DownloadStatus.paused
                    ? 'Paused · $downloaded / $total'
                    : '$pct% · $downloaded / $total',
            style: context.text.bodyMedium?.copyWith(
              fontSize: 11,
              color: task.status == DownloadStatus.failed
                  ? Colors.orangeAccent
                  : colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms);
  }
}

class _CompletedTile extends StatelessWidget {
  const _CompletedTile({required this.task, required this.ref});
  final DownloadTask task;
  final WidgetRef ref;

  VideoFile _toVideo() => VideoFile(
        id: task.id,
        title: task.title,
        path: task.filePath,
        duration: Duration.zero,
        size: task.totalBytes,
        dateAdded: task.createdAt,
        mimeType: 'video/*',
        folderName: 'Downloads',
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notifier = ref.read(downloadsProvider.notifier);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => notifier.delete(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: ListTile(
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.accentSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.download_done_rounded, color: colors.accent),
          ),
          title: Text(task.title,
              style: context.text.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            task.totalBytes.toReadableSize(),
            style: context.text.bodyMedium?.copyWith(fontSize: 12),
          ),
          trailing: Icon(Icons.play_circle_outline,
              color: colors.textSecondary, size: 24),
          onTap: () => context.push('/player', extra: _toVideo()),
        ),
      ).animate().fadeIn(duration: 150.ms),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Download'),
            content: Text('Delete "${task.title}" from your device?'),
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
          Icon(Icons.download_rounded, size: 72, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text('No downloads yet',
              style: context.text.titleMedium
                  ?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 8),
          Text('Tap + to download a video from a URL',
              style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
