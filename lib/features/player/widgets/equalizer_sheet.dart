import 'package:flutter/material.dart';
import '../controllers/player_controller.dart';

class EqualizerSheet extends StatefulWidget {
  const EqualizerSheet({
    super.key,
    required this.controller,
    required this.initialBands,
    required this.onBandsChanged,
  });

  final PlayerController controller;
  final List<double> initialBands;
  final void Function(List<double>) onBandsChanged;

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  static const _labels = ['Bass', 'Low\nMid', 'Mid', 'High\nMid', 'Treble'];
  static const _freqs = ['60Hz', '250Hz', '1kHz', '4kHz', '16kHz'];

  late List<double> _bands;

  @override
  void initState() {
    super.initState();
    _bands = List<double>.from(widget.initialBands);
  }

  void _setBand(int i, double v) {
    setState(() => _bands[i] = (v * 2).round() / 2.0); // 0.5 dB steps
    widget.controller.setEq(_bands);
    widget.onBandsChanged(List.unmodifiable(_bands));
  }

  void _reset() {
    setState(() => _bands = List.filled(5, 0.0));
    widget.controller.setEq(_bands);
    widget.onBandsChanged(List.unmodifiable(_bands));
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF252535);
    const accent = Color(0xFF7C4DFF);
    final isFlat = _bands.every((b) => b == 0.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title row
            Row(
              children: [
                const Icon(Icons.equalizer_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Equalizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isFlat)
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // dB scale labels
            Row(
              children: [
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _DbLabel('+12'),
                    const SizedBox(height: 20),
                    _DbLabel('+6'),
                    const SizedBox(height: 20),
                    _DbLabel('0'),
                    const SizedBox(height: 20),
                    _DbLabel('-6'),
                    const SizedBox(height: 20),
                    _DbLabel('-12'),
                  ],
                ),
                const SizedBox(width: 8),
                // Zero line
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        // Center zero line
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 1,
                                color: Colors.white12,
                              ),
                            ],
                          ),
                        ),
                        // Band sliders
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(5, (i) {
                            return _BandSlider(
                              value: _bands[i],
                              label: _labels[i],
                              freq: _freqs[i],
                              accent: accent,
                              onChanged: (v) => _setBand(i, v),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.entries.map((e) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _bands = List<double>.from(e.value));
                      widget.controller.setEq(_bands);
                      widget.onBandsChanged(List.unmodifiable(_bands));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _presets = <String, List<double>>{
    'Flat': [0, 0, 0, 0, 0],
    'Bass Boost': [8, 4, 0, -2, -2],
    'Treble Boost': [-2, -2, 0, 4, 8],
    'Vocal': [-2, 2, 6, 4, -1],
    'Rock': [5, 2, -1, 3, 5],
    'Pop': [-1, 3, 5, 3, -1],
    'Jazz': [3, 2, 0, 2, 4],
    'Classical': [5, 3, -2, 3, 5],
    'Night Mode': [-4, 2, 4, 2, -4],
  };
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.value,
    required this.label,
    required this.freq,
    required this.accent,
    required this.onChanged,
  });

  final double value;
  final String label;
  final String freq;
  final Color accent;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = value != 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value >= 0 ? '+${value.toStringAsFixed(1)}' : value.toStringAsFixed(1),
          style: TextStyle(
            color: isActive ? accent : Colors.white30,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 160,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: isActive ? accent : Colors.white30,
                inactiveTrackColor: Colors.white12,
                thumbColor: isActive ? accent : Colors.white54,
                overlayColor: accent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: value,
                min: -12.0,
                max: 12.0,
                divisions: 48,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          freq,
          style: const TextStyle(color: Colors.white24, fontSize: 9),
        ),
      ],
    );
  }
}

class _DbLabel extends StatelessWidget {
  const _DbLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white24, fontSize: 9),
    );
  }
}
