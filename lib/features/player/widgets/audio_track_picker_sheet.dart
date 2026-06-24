import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class AudioTrackPickerSheet extends StatelessWidget {
  const AudioTrackPickerSheet({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    final tracks = player.state.tracks.audio
        .where((t) => t.id != 'no' && t.id != 'auto')
        .toList();
    final current = player.state.track.audio;

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
              'Audio Track',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No alternate audio tracks available.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...tracks.map((t) {
                final isSelected = current.id == t.id;
                final label = t.title?.isNotEmpty == true
                    ? t.title!
                    : (t.language?.isNotEmpty == true
                        ? t.language!
                        : 'Track ${tracks.indexOf(t) + 1}');
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color:
                        isSelected ? Colors.cyanAccent : Colors.white54,
                    size: 20,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  subtitle: t.language != null && t.title != null
                      ? Text(t.language!,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11))
                      : null,
                  onTap: () {
                    player.setAudioTrack(t);
                    Navigator.pop(context);
                  },
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
