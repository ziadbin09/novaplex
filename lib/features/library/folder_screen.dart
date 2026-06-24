import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/privacy_repository.dart';
import 'widgets/pin_dialog.dart';

class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final foldersAsync = ref.watch(videosByFolderProvider);
    final hidden = ref.watch(hiddenFoldersProvider);
    final unlocked = ref.watch(privateUnlockedProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text('Folders', style: context.text.displayMedium),
                  const Spacer(),
                  if (unlocked)
                    TextButton.icon(
                      onPressed: () => ref
                          .read(privateUnlockedProvider.notifier)
                          .lock(),
                      icon: Icon(Icons.lock_rounded,
                          size: 16, color: colors.accent),
                      label: Text('Lock',
                          style: TextStyle(
                              color: colors.accent, fontSize: 13)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: foldersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Error loading folders')),
                data: (folders) => ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    ...folders.keys.map((folder) {
                      final videos = folders[folder]!;
                      final totalDuration = videos.fold<Duration>(
                          Duration.zero, (acc, v) => acc + v.duration);
                      final isHidden = hidden.contains(folder);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.accentSubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isHidden
                                ? Icons.folder_special_rounded
                                : Icons.folder_rounded,
                            color: colors.accent,
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(folder,
                                  style: context.text.titleMedium,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (isHidden) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.lock_rounded,
                                  size: 14, color: colors.accent),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${videos.length} videos · ${totalDuration.toShortLabel()}',
                          style: context.text.bodyMedium,
                        ),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: colors.textSecondary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () =>
                            context.push('/folders/detail', extra: folder),
                        onLongPress: () => _showFolderOptions(
                            context, ref, folder, isHidden),
                      );
                    }),
                    // Locked private section entry
                    if (hidden.isNotEmpty && !unlocked)
                      _PrivateFoldersTile(
                        count: hidden.length,
                        onTap: () => _unlockPrivate(context, ref),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlockPrivate(BuildContext context, WidgetRef ref) async {
    final pin = await showPinDialog(
      context,
      title: 'Private Folders',
      subtitle: 'Enter your PIN to unlock',
    );
    if (pin == null) return;
    if (ref.read(privacyPinProvider).verify(pin)) {
      ref.read(privateUnlockedProvider.notifier).unlock();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN')),
      );
    }
  }

  void _showFolderOptions(
      BuildContext context, WidgetRef ref, String folder, bool isHidden) {
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
              leading: Icon(
                isHidden
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                color: colors.accent,
              ),
              title: Text(
                isHidden ? 'Unhide folder' : 'Hide folder',
                style: context.text.bodyLarge,
              ),
              subtitle: Text(
                isHidden
                    ? 'Show "$folder" in the library again'
                    : 'Move "$folder" behind your PIN',
                style: context.text.bodyMedium?.copyWith(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                if (isHidden) {
                  ref.read(hiddenFoldersProvider.notifier).unhide(folder);
                } else {
                  _hideFolder(context, ref, folder);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _hideFolder(
      BuildContext context, WidgetRef ref, String folder) async {
    final pinRepo = ref.read(privacyPinProvider);
    if (!pinRepo.isSet) {
      final pin = await showPinDialog(
        context,
        title: 'Set a PIN',
        subtitle: 'Choose a 4-digit PIN to protect private folders',
      );
      if (pin == null) return;
      pinRepo.setPin(pin);
    }
    ref.read(hiddenFoldersProvider.notifier).hide(folder);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$folder" is now private')),
      );
    }
  }
}

class _PrivateFoldersTile extends StatelessWidget {
  const _PrivateFoldersTile({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child:
            Icon(Icons.lock_rounded, color: colors.textSecondary, size: 22),
      ),
      title: Text('Private folders', style: context.text.titleMedium),
      subtitle: Text(
        '$count hidden ${count == 1 ? 'folder' : 'folders'} · tap to unlock',
        style: context.text.bodyMedium,
      ),
      trailing:
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
