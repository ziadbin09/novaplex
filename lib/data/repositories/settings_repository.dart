import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with override in main');
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.accentColor = AppColors.accentViolet,
    this.accentColorSecondary,
    this.skipDuration = AppConstants.defaultSkipSeconds,
    this.brightnessGesture = true,
    this.volumeGesture = true,
    this.seekGesture = true,
    this.haptics = true,
    this.hardwareDecode = false,
    this.showSeekThumbnail = true,
    this.subtitleSize = 16.0,
    this.subtitleColor = Colors.white,
    this.subtitleBgOpacity = 0.5,
    this.autoPlayNext = true,
    this.eqBands = const [0.0, 0.0, 0.0, 0.0, 0.0],
  });

  final AppThemeMode themeMode;
  final Color accentColor;
  final Color? accentColorSecondary;
  final int skipDuration;
  final bool brightnessGesture;
  final bool volumeGesture;
  final bool seekGesture;
  final bool haptics;
  final bool hardwareDecode;
  final bool showSeekThumbnail;
  final double subtitleSize;
  final Color subtitleColor;
  final double subtitleBgOpacity;
  final bool autoPlayNext;
  // 5 bands: Bass(~60Hz), Low-Mid(~250Hz), Mid(~1kHz), High-Mid(~4kHz), Treble(~16kHz)
  // Values in dB, range -12 to +12
  final List<double> eqBands;

  bool get eqEnabled => eqBands.any((b) => b != 0.0);

  AppSettings copyWith({
    AppThemeMode? themeMode,
    Color? accentColor,
    Color? accentColorSecondary,
    bool clearAccentColorSecondary = false,
    int? skipDuration,
    bool? brightnessGesture,
    bool? volumeGesture,
    bool? seekGesture,
    bool? haptics,
    bool? hardwareDecode,
    bool? showSeekThumbnail,
    double? subtitleSize,
    Color? subtitleColor,
    double? subtitleBgOpacity,
    bool? autoPlayNext,
    List<double>? eqBands,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      accentColorSecondary: clearAccentColorSecondary
          ? null
          : (accentColorSecondary ?? this.accentColorSecondary),
      skipDuration: skipDuration ?? this.skipDuration,
      brightnessGesture: brightnessGesture ?? this.brightnessGesture,
      volumeGesture: volumeGesture ?? this.volumeGesture,
      seekGesture: seekGesture ?? this.seekGesture,
      haptics: haptics ?? this.haptics,
      hardwareDecode: hardwareDecode ?? this.hardwareDecode,
      showSeekThumbnail: showSeekThumbnail ?? this.showSeekThumbnail,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitleBgOpacity: subtitleBgOpacity ?? this.subtitleBgOpacity,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      eqBands: eqBands ?? this.eqBands,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.read(sharedPrefsProvider);
    return _load(prefs);
  }

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  static AppSettings _load(SharedPreferences prefs) {
    final themeModeIdx = prefs.getInt(AppConstants.keyThemeMode) ?? 0;
    final accentValue = prefs.getInt(AppConstants.keyAccentColor) ??
        AppColors.accentViolet.toARGB32();
    final accentSecondaryValue =
        prefs.getInt(AppConstants.keyAccentColorSecondary);
    return AppSettings(
      themeMode: AppThemeMode.values[
          themeModeIdx.clamp(0, AppThemeMode.values.length - 1)],
      accentColor: Color(accentValue),
      accentColorSecondary:
          accentSecondaryValue != null ? Color(accentSecondaryValue) : null,
      skipDuration: prefs.getInt(AppConstants.keySkipDuration) ?? 10,
      brightnessGesture:
          prefs.getBool(AppConstants.keyBrightnessGesture) ?? true,
      volumeGesture: prefs.getBool(AppConstants.keyVolumeGesture) ?? true,
      seekGesture: prefs.getBool(AppConstants.keySeekGesture) ?? true,
      haptics: prefs.getBool(AppConstants.keyHaptics) ?? true,
      hardwareDecode: prefs.getBool(AppConstants.keyHardwareDecode) ?? false,
      showSeekThumbnail:
          prefs.getBool(AppConstants.keyShowThumbnailOnSeek) ?? true,
      subtitleSize: prefs.getDouble(AppConstants.keySubtitleSize) ?? 16.0,
      subtitleColor: Color(
          prefs.getInt(AppConstants.keySubtitleColor) ??
              Colors.white.toARGB32()),
      subtitleBgOpacity:
          prefs.getDouble(AppConstants.keySubtitleBgOpacity) ?? 0.5,
      autoPlayNext: prefs.getBool(AppConstants.keyAutoPlayNext) ?? true,
      eqBands: prefs.getStringList(AppConstants.keyEqBands)
              ?.map(double.parse)
              .toList() ??
          const [0.0, 0.0, 0.0, 0.0, 0.0],
    );
  }

  void setThemeMode(AppThemeMode mode) {
    _prefs.setInt(AppConstants.keyThemeMode, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  void setAccentPreset(AccentPreset preset) {
    _prefs.setInt(AppConstants.keyAccentColor, preset.primary.toARGB32());
    if (preset.secondary != null) {
      _prefs.setInt(
          AppConstants.keyAccentColorSecondary, preset.secondary!.toARGB32());
    } else {
      _prefs.remove(AppConstants.keyAccentColorSecondary);
    }
    state = state.copyWith(
      accentColor: preset.primary,
      accentColorSecondary: preset.secondary,
      clearAccentColorSecondary: preset.secondary == null,
    );
  }

  void setSkipDuration(int seconds) {
    _prefs.setInt(AppConstants.keySkipDuration, seconds);
    state = state.copyWith(skipDuration: seconds);
  }

  void setBrightnessGesture(bool v) {
    _prefs.setBool(AppConstants.keyBrightnessGesture, v);
    state = state.copyWith(brightnessGesture: v);
  }

  void setVolumeGesture(bool v) {
    _prefs.setBool(AppConstants.keyVolumeGesture, v);
    state = state.copyWith(volumeGesture: v);
  }

  void setSeekGesture(bool v) {
    _prefs.setBool(AppConstants.keySeekGesture, v);
    state = state.copyWith(seekGesture: v);
  }

  void setHaptics(bool v) {
    _prefs.setBool(AppConstants.keyHaptics, v);
    state = state.copyWith(haptics: v);
  }

  void setHardwareDecode(bool v) {
    _prefs.setBool(AppConstants.keyHardwareDecode, v);
    state = state.copyWith(hardwareDecode: v);
  }

  void setShowSeekThumbnail(bool v) {
    _prefs.setBool(AppConstants.keyShowThumbnailOnSeek, v);
    state = state.copyWith(showSeekThumbnail: v);
  }

  void setSubtitleSize(double v) {
    _prefs.setDouble(AppConstants.keySubtitleSize, v);
    state = state.copyWith(subtitleSize: v);
  }

  void setSubtitleColor(Color v) {
    _prefs.setInt(AppConstants.keySubtitleColor, v.toARGB32());
    state = state.copyWith(subtitleColor: v);
  }

  void setSubtitleBgOpacity(double v) {
    _prefs.setDouble(AppConstants.keySubtitleBgOpacity, v);
    state = state.copyWith(subtitleBgOpacity: v);
  }

  void setAutoPlayNext(bool v) {
    _prefs.setBool(AppConstants.keyAutoPlayNext, v);
    state = state.copyWith(autoPlayNext: v);
  }

  void setEqBands(List<double> bands) {
    _prefs.setStringList(
        AppConstants.keyEqBands, bands.map((b) => b.toString()).toList());
    state = state.copyWith(eqBands: List.unmodifiable(bands));
  }
}
