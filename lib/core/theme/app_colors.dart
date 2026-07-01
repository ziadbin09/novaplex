import 'package:flutter/material.dart';

/// An accent color choice. [secondary] is null for plain single-color
/// presets; when set, it's used as a companion highlight (slider thumb,
/// switch track) alongside [primary] as the main accent.
@immutable
class AccentPreset {
  const AccentPreset(this.primary, [this.secondary]);
  final Color primary;
  final Color? secondary;
}

class AppColors {
  AppColors._();

  // Base dark palette
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF12121A);
  static const Color surfaceAltDark = Color(0xFF1C1C28);
  static const Color borderDark = Color(0xFF2A2A3D);
  static const Color textPrimaryDark = Color(0xFFF0F0FF);
  static const Color textSecondaryDark = Color(0xFF8888A8);

  // AMOLED
  static const Color bgAmoled = Color(0xFF000000);
  static const Color surfaceAmoled = Color(0xFF0D0D0D);
  static const Color surfaceAltAmoled = Color(0xFF1A1A1A);

  // Light palette
  static const Color bgLight = Color(0xFFF5F5FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFEEEEF5);
  static const Color borderLight = Color(0xFFDDDDE8);
  static const Color textPrimaryLight = Color(0xFF12121A);
  static const Color textSecondaryLight = Color(0xFF6666AA);

  // Accent presets
  static const Color accentViolet = Color(0xFF7C6FFF);
  static const Color accentBlue = Color(0xFF4D8EFF);
  static const Color accentTeal = Color(0xFF00778F); // Manzar logo teal
  static const Color accentGreen = Color(0xFF00D68F);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentRed = Color(0xFFFF5C5C);
  static const Color accentPink = Color(0xFFFF5FA3);
  static const Color accentAmber = Color(0xFFF8A748); // Manzar logo amber

  static const List<AccentPreset> accentPresets = [
    AccentPreset(accentTeal, accentAmber), // Manzar brand combo
    AccentPreset(accentViolet),
    AccentPreset(accentBlue),
    AccentPreset(accentGreen),
    AccentPreset(accentOrange),
    AccentPreset(accentRed),
    AccentPreset(accentPink),
  ];

  // Player UI
  static const Color playerOverlay = Color(0x99000000);
  static const Color playerOverlayLight = Color(0x44000000);
  static const Color seekBarBg = Color(0x44FFFFFF);
  static const Color seekBarBuffered = Color(0x88FFFFFF);
}
