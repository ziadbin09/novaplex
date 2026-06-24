import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../data/services/subtitle_scanner.dart';

class SubtitlePickerSheet extends StatelessWidget {
  const SubtitlePickerSheet({
    super.key,
    required this.player,
    required this.videoPath,
    required this.currentTrack,
  });

  final Player player;
  final String videoPath;
  final SubtitleTrack currentTrack;

  @override
  Widget build(BuildContext context) {
    final externalFiles = SubtitleScanner.scan(videoPath);
    final embeddedTracks = player.state.tracks.subtitle
        .where((t) => t.id != 'no' && t.id != 'auto')
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
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
            const SizedBox(height: 12),
            const Text(
              'Subtitles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Off option
            _TrackTile(
              label: 'Off',
              isSelected: currentTrack.id == 'no',
              onTap: () {
                player.setSubtitleTrack(SubtitleTrack.no());
                Navigator.pop(context);
              },
            ),
            // Embedded tracks
            if (embeddedTracks.isNotEmpty) ...[
              const _SectionHeader(label: 'Embedded'),
              ...embeddedTracks.map((t) => _TrackTile(
                    label: t.title ?? t.language ?? 'Track ${t.id}',
                    isSelected: currentTrack.id == t.id,
                    onTap: () {
                      player.setSubtitleTrack(t);
                      Navigator.pop(context);
                    },
                  )),
            ],
            // External files
            if (externalFiles.isNotEmpty) ...[
              const _SectionHeader(label: 'External'),
              ...externalFiles.map((f) => _TrackTile(
                    label: f.label,
                    subtitle: f.path.split('/').last,
                    isSelected: currentTrack.id == f.uri,
                    onTap: () {
                      player.setSubtitleTrack(
                          SubtitleTrack.uri(f.uri, title: f.label));
                      Navigator.pop(context);
                    },
                  )),
            ],
            if (embeddedTracks.isEmpty && externalFiles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No subtitle files found.\nPlace .srt or .ass files next to your video.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: isSelected ? Colors.cyanAccent : Colors.white54,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 11))
          : null,
      onTap: onTap,
    );
  }
}
