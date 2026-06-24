import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/recent_urls_repository.dart';

/// Dialog that lets the user paste or type a network video URL.
/// Returns the trimmed URL string, or null if cancelled.
/// Played URLs are remembered (last 10) and offered as one-tap recents.
Future<String?> showPlayUrlDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _PlayUrlDialog(),
  );
}

class _PlayUrlDialog extends ConsumerStatefulWidget {
  const _PlayUrlDialog();

  @override
  ConsumerState<_PlayUrlDialog> createState() => _PlayUrlDialogState();
}

class _PlayUrlDialogState extends ConsumerState<_PlayUrlDialog> {
  final _controller = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isUrl(String v) {
    final t = v.trim();
    return t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.startsWith('rtmp://') ||
        t.startsWith('rtsp://');
  }

  void _submit(String url) {
    final trimmed = url.trim();
    if (!_isUrl(trimmed)) return;
    ref.read(recentUrlsProvider.notifier).add(trimmed);
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recents = ref.watch(recentUrlsProvider);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.link_rounded, color: colors.accent, size: 22),
          const SizedBox(width: 10),
          Text('Play from URL', style: context.text.titleMedium),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: context.text.bodyLarge,
              decoration: InputDecoration(
                hintText: 'https://example.com/video.mp4',
                hintStyle: context.text.bodyLarge
                    ?.copyWith(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _valid = false);
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _valid = _isUrl(v)),
              onSubmitted: _submit,
            ),
            if (recents.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('RECENT',
                  style: context.text.bodyMedium?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colors.accent,
                  )),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recents.length,
                  itemBuilder: (_, i) {
                    final url = recents[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history_rounded,
                          color: colors.textSecondary, size: 18),
                      title: Text(
                        url,
                        style: context.text.bodyMedium
                            ?.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: colors.textSecondary, size: 16),
                        onPressed: () => ref
                            .read(recentUrlsProvider.notifier)
                            .remove(url),
                      ),
                      onTap: () => _submit(url),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        FilledButton(
          onPressed: _valid ? () => _submit(_controller.text) : null,
          style: FilledButton.styleFrom(backgroundColor: colors.accent),
          child: const Text('Play'),
        ),
      ],
    );
  }
}
