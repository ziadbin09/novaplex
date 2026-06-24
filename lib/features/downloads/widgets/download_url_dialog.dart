import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DownloadRequest {
  const DownloadRequest({required this.url, required this.title});
  final String url;
  final String title;
}

/// Dialog to enter a video URL (and optional title) to download.
/// Returns a [DownloadRequest], or null if cancelled.
Future<DownloadRequest?> showDownloadUrlDialog(BuildContext context) {
  return showDialog<DownloadRequest>(
    context: context,
    builder: (_) => const _DownloadUrlDialog(),
  );
}

class _DownloadUrlDialog extends StatefulWidget {
  const _DownloadUrlDialog();

  @override
  State<_DownloadUrlDialog> createState() => _DownloadUrlDialogState();
}

class _DownloadUrlDialogState extends State<_DownloadUrlDialog> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  bool _isUrl(String v) {
    final t = v.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  String _deriveTitle(String url) {
    try {
      final name = Uri.parse(url).pathSegments.last;
      return name.isEmpty ? 'Download' : name;
    } catch (_) {
      return 'Download';
    }
  }

  void _submit() {
    final url = _urlController.text.trim();
    if (!_isUrl(url)) return;
    final title = _titleController.text.trim().isEmpty
        ? _deriveTitle(url)
        : _titleController.text.trim();
    Navigator.of(context).pop(DownloadRequest(url: url, title: title));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.download_rounded, color: colors.accent, size: 22),
          const SizedBox(width: 10),
          Text('Download Video', style: context.text.titleMedium),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _urlController,
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
            ),
            onChanged: (v) => setState(() => _valid = _isUrl(v)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            style: context.text.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Title (optional)',
              hintStyle: context.text.bodyLarge
                  ?.copyWith(color: colors.textSecondary),
              filled: true,
              fillColor: colors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _valid ? _submit() : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          style: FilledButton.styleFrom(backgroundColor: colors.accent),
          child: const Text('Download'),
        ),
      ],
    );
  }
}
