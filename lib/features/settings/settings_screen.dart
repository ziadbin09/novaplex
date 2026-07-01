import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/privacy_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../library/widgets/pin_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Settings', style: context.text.displayMedium),
              ),
            ),

            // --- APPEARANCE ---
            _SectionHeader(title: 'Appearance'),
            SliverToBoxAdapter(
              child: _SettingsCard(children: [
                _ThemeTile(settings: settings, notifier: notifier),
                Divider(color: colors.border, height: 1),
                _AccentColorTile(settings: settings, notifier: notifier),
              ]),
            ),

            // --- PLAYER ---
            _SectionHeader(title: 'Player'),
            SliverToBoxAdapter(
              child: _SettingsCard(children: [
                _SkipDurationTile(settings: settings, notifier: notifier),
                Divider(color: colors.border, height: 1),
                _SwitchTile(
                  icon: Icons.hd_outlined,
                  label: 'Hardware Decode',
                  subtitle: 'Faster playback on supported devices',
                  value: settings.hardwareDecode,
                  onChanged: notifier.setHardwareDecode,
                ),
                Divider(color: colors.border, height: 1),
                _SwitchTile(
                  icon: Icons.image_outlined,
                  label: 'Thumbnail on Seek',
                  subtitle: 'Preview frame while seeking',
                  value: settings.showSeekThumbnail,
                  onChanged: notifier.setShowSeekThumbnail,
                ),
                Divider(color: colors.border, height: 1),
                _SwitchTile(
                  icon: Icons.vibration_rounded,
                  label: 'Haptic Feedback',
                  value: settings.haptics,
                  onChanged: notifier.setHaptics,
                ),
                Divider(color: colors.border, height: 1),
                _SwitchTile(
                  icon: Icons.queue_play_next_rounded,
                  label: 'Auto-play Next',
                  subtitle: 'Play the next video in the folder when one ends',
                  value: settings.autoPlayNext,
                  onChanged: notifier.setAutoPlayNext,
                ),
              ]),
            ),

            // --- GESTURES ---
            _SectionHeader(title: 'Gestures'),
            SliverToBoxAdapter(
              child: _SettingsCard(children: [
                _SwitchTile(
                  icon: Icons.brightness_6_outlined,
                  label: 'Brightness Swipe',
                  subtitle: 'Swipe left side to control brightness',
                  value: settings.brightnessGesture,
                  onChanged: notifier.setBrightnessGesture,
                ),
                Divider(color: colors.border, height: 1),
                _SwitchTile(
                  icon: Icons.volume_up_outlined,
                  label: 'Volume Swipe',
                  subtitle: 'Swipe right side to control volume',
                  value: settings.volumeGesture,
                  onChanged: notifier.setVolumeGesture,
                ),
                Divider(color: colors.border, height: 1),
                _SwitchTile(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Horizontal Seek',
                  subtitle: 'Swipe horizontally to seek',
                  value: settings.seekGesture,
                  onChanged: notifier.setSeekGesture,
                ),
              ]),
            ),

            // --- SUBTITLES ---
            _SectionHeader(title: 'Subtitles'),
            SliverToBoxAdapter(
              child: _SettingsCard(children: [
                _SubtitleSizeTile(settings: settings, notifier: notifier),
                Divider(color: colors.border, height: 1),
                _SubtitleBgOpacityTile(settings: settings, notifier: notifier),
                Divider(color: colors.border, height: 1),
                _SubtitleColorTile(settings: settings, notifier: notifier),
              ]),
            ),

            // --- PRIVACY ---
            _SectionHeader(title: 'Privacy'),
            SliverToBoxAdapter(
              child: _SettingsCard(children: [
                _PinTile(ref: ref),
              ]),
            ),

            // --- ABOUT ---
            _SectionHeader(title: 'About'),
            SliverToBoxAdapter(
              child: _SettingsCard(children: [
                _InfoTile(icon: Icons.info_outline, label: 'Version',
                    value: '1.0.0'),
                Divider(color: colors.border, height: 1),
                _InfoTile(icon: Icons.movie_outlined, label: 'App',
                    value: 'Manzar'),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Section header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          title.toUpperCase(),
          style: context.text.bodyMedium?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.colors.accent,
          ),
        ),
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}

// â”€â”€â”€ Card wrapper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0);
  }
}

// â”€â”€â”€ Tiles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SwitchTile extends ConsumerWidget {
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: colors.accentSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colors.accent, size: 18),
      ),
      title: Text(label, style: context.text.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!, style: context.text.bodyMedium?.copyWith(fontSize: 12))
          : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themes = [
      (AppThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
      (AppThemeMode.amoled, Icons.nights_stay_outlined, 'AMOLED'),
      (AppThemeMode.light, Icons.light_mode_outlined, 'Light'),
      (AppThemeMode.system, Icons.brightness_auto_outlined, 'System'),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_outlined, color: colors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Theme', style: context.text.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: themes.map((t) {
              final selected = settings.themeMode == t.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(t.$1),
                  child: AnimatedContainer(
                    duration: 150.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? colors.accent : colors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(t.$2,
                            size: 20,
                            color: selected ? Colors.white : colors.textSecondary),
                        const SizedBox(height: 4),
                        Text(t.$3,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: selected ? Colors.white : colors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AccentColorTile extends StatelessWidget {
  const _AccentColorTile({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.color_lens_outlined,
                    color: colors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Accent Color', style: context.text.bodyLarge),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.accentPresets.map((preset) {
              final selected = settings.accentColor.toARGB32() ==
                      preset.primary.toARGB32() &&
                  settings.accentColorSecondary?.toARGB32() ==
                      preset.secondary?.toARGB32();
              return GestureDetector(
                onTap: () => notifier.setAccentPreset(preset),
                child: AnimatedContainer(
                  duration: 150.ms,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: preset.secondary != null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [preset.primary, preset.secondary!],
                            stops: const [0.5, 0.5],
                          )
                        : null,
                    color: preset.secondary == null ? preset.primary : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: preset.primary.withValues(alpha: 0.5), blurRadius: 8)]
                        : [],
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SkipDurationTile extends StatelessWidget {
  const _SkipDurationTile({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final durations = [5, 10, 15, 20, 30];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.skip_next_outlined,
                    color: colors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Skip Duration', style: context.text.bodyLarge),
              const Spacer(),
              Text('${settings.skipDuration}s',
                  style: context.text.bodyMedium
                      ?.copyWith(color: colors.accent, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: durations.map((d) {
              final selected = settings.skipDuration == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setSkipDuration(d),
                  child: AnimatedContainer(
                    duration: 150.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected ? colors.accent : colors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text('${d}s',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected ? Colors.white : colors.textSecondary,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SubtitleSizeTile extends StatelessWidget {
  const _SubtitleSizeTile({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: colors.accentSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.format_size_rounded, color: colors.accent, size: 18),
      ),
      title: Text('Subtitle Size', style: context.text.bodyLarge),
      subtitle: Slider(
        value: settings.subtitleSize,
        min: 10,
        max: 28,
        divisions: 9,
        label: '${settings.subtitleSize.round()}pt',
        onChanged: notifier.setSubtitleSize,
      ),
    );
  }
}

class _SubtitleBgOpacityTile extends StatelessWidget {
  const _SubtitleBgOpacityTile(
      {required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: colors.accentSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.opacity_rounded, color: colors.accent, size: 18),
      ),
      title: Text('Subtitle Background', style: context.text.bodyLarge),
      subtitle: Slider(
        value: settings.subtitleBgOpacity,
        min: 0,
        max: 1,
        divisions: 10,
        label: '${(settings.subtitleBgOpacity * 100).round()}%',
        onChanged: notifier.setSubtitleBgOpacity,
      ),
    );
  }
}

class _PinTile extends ConsumerWidget {
  const _PinTile({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final colors = context.colors;
    final pinRepo = ref.read(privacyPinProvider);
    final hiddenCount = ref.watch(hiddenFoldersProvider).length;

    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: colors.accentSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.pin_rounded, color: colors.accent, size: 18),
      ),
      title: Text(pinRepo.isSet ? 'Change PIN' : 'Set PIN',
          style: context.text.bodyLarge),
      subtitle: Text(
        hiddenCount > 0
            ? '$hiddenCount private ${hiddenCount == 1 ? 'folder' : 'folders'}'
            : 'Protects private folders',
        style: context.text.bodyMedium?.copyWith(fontSize: 12),
      ),
      trailing:
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
      onTap: () => _changePin(context, pinRepo),
    );
  }

  Future<void> _changePin(BuildContext context, PrivacyPin pinRepo) async {
    if (pinRepo.isSet) {
      final current = await showPinDialog(
        context,
        title: 'Current PIN',
        subtitle: 'Enter your current PIN first',
      );
      if (current == null) return;
      if (!pinRepo.verify(current)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong PIN')),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;
    final next = await showPinDialog(
      context,
      title: 'New PIN',
      subtitle: 'Choose a 4-digit PIN',
    );
    if (next == null) return;
    pinRepo.setPin(next);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated')),
      );
    }
  }
}

class _SubtitleColorTile extends StatelessWidget {
  const _SubtitleColorTile({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  static const _presets = [
    Colors.white,
    Color(0xFFFFEB3B), // yellow
    Color(0xFF00E5FF), // cyan
    Color(0xFF69F0AE), // green
    Color(0xFFFFAB91), // peach
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: colors.accentSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.text_format_rounded, color: colors.accent, size: 18),
      ),
      title: Text('Subtitle Color', style: context.text.bodyLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: _presets.map((c) {
            final selected =
                settings.subtitleColor.toARGB32() == c.toARGB32();
            return GestureDetector(
              onTap: () => notifier.setSubtitleColor(c),
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.accent : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.black, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: colors.accentSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colors.accent, size: 18),
      ),
      title: Text(label, style: context.text.bodyLarge),
      trailing: Text(value, style: context.text.bodyMedium),
    );
  }
}
