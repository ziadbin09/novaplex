import 'package:flutter/material.dart';
import '../controllers/player_controller.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key, required this.controller});
  final PlayerController controller;

  static const _presets = [
    (label: '15 min', minutes: 15),
    (label: '30 min', minutes: 30),
    (label: '45 min', minutes: 45),
    (label: '60 min', minutes: 60),
    (label: '90 min', minutes: 90),
    (label: 'End of video', minutes: -1),
  ];

  @override
  Widget build(BuildContext context) {
    final active = controller.sleepTimerRemaining;

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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Sleep Timer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (active != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _formatRemaining(active),
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (active != null) ...[
            ListTile(
              leading: const Icon(Icons.timer_off_outlined,
                  color: Colors.redAccent, size: 22),
              title: const Text('Cancel Timer',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                controller.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white12, height: 1),
          ],
          ..._presets.map((p) => ListTile(
                leading: Icon(
                  p.minutes == -1
                      ? Icons.movie_outlined
                      : Icons.timer_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
                title: Text(p.label,
                    style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  if (p.minutes == -1) {
                    controller.setSleepTimerEndOfVideo();
                  } else {
                    controller
                        .setSleepTimer(Duration(minutes: p.minutes));
                  }
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
