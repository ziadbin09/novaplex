import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/video_file.dart';

class VideoInfoSheet extends StatelessWidget {
  const VideoInfoSheet({super.key, required this.video});
  final VideoFile video;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Title', video.title.replaceAll(RegExp(r'\.[^.]+$'), '')),
      ('Resolution', video.resolutionLabel.isNotEmpty
          ? '${video.width} × ${video.height}  (${video.resolutionLabel})'
          : '${video.width} × ${video.height}'),
      ('Duration', video.duration.toHhMmSs()),
      ('File size', video.size.toReadableSize()),
      ('Format', video.mimeType.isNotEmpty ? video.mimeType : 'Unknown'),
      ('Folder', video.folderName.isNotEmpty ? video.folderName : '—'),
      ('Path', video.path),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'Video Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((r) => _InfoRow(label: r.$1, value: r.$2)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xDEFFFFFF),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
