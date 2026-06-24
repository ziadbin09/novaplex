import 'package:flutter/material.dart';
import '../controllers/player_controller.dart';

/// Audio & subtitle sync adjusters (±0.1s steps).
class SyncSheet extends StatefulWidget {
  const SyncSheet({super.key, required this.controller});
  final PlayerController controller;

  @override
  State<SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<SyncSheet> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
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
          const Text(
            'Audio & Subtitle Sync',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _DelayRow(
            icon: Icons.audiotrack_outlined,
            label: 'Audio Delay',
            value: c.audioDelay,
            onChanged: (v) async {
              await c.setAudioDelay(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          _DelayRow(
            icon: Icons.subtitles_outlined,
            label: 'Subtitle Delay',
            value: c.subtitleDelay,
            onChanged: (v) async {
              await c.setSubtitleDelay(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              await c.setAudioDelay(0);
              await c.setSubtitleDelay(0);
              setState(() {});
            },
            child: const Text('Reset both',
                style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DelayRow extends StatelessWidget {
  const _DelayRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final double value;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: () => onChanged(value - 0.1),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}s',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: value == 0 ? Colors.white54 : Colors.cyanAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () => onChanged(value + 0.1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
