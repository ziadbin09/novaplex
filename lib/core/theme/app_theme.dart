import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

enum AppThemeMode { dark, light, amoled, system }

class AppTheme {
  AppTheme._();

  static ThemeData dark(Color accent) => _build(
        brightness: Brightness.dark,
        bg: AppColors.bgDark,
        surface: AppColors.surfaceDark,
        surfaceAlt: AppColors.surfaceAltDark,
        border: AppColors.borderDark,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        accent: accent,
      );

  static ThemeData amoled(Color accent) => _build(
        brightness: Brightness.dark,
        bg: AppColors.bgAmoled,
        surface: AppColors.surfaceAmoled,
        surfaceAlt: AppColors.surfaceAltAmoled,
        border: AppColors.borderDark,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        accent: accent,
      );

  static ThemeData light(Color accent) => _build(
        brightness: Brightness.light,
        bg: AppColors.bgLight,
        surface: AppColors.surfaceLight,
        surfaceAlt: AppColors.surfaceAltLight,
        border: AppColors.borderLight,
        textPrimary: AppColors.textPrimaryLight,
        textSecondary: AppColors.textSecondaryLight,
        accent: accent,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceAlt,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
      displayMedium: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary),
      titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
      bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
      labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent.withValues(alpha: 0.7),
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: AppColors.accentRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: bg,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: bg,
              ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: accent);
          }
          return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent, size: 22);
          }
          return IconThemeData(color: textSecondary, size: 22);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: border,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? accent.withValues(alpha: 0.4)
                : border),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 0),
      extensions: [
        AppColorExtension(
          bg: bg,
          surface: surface,
          surfaceAlt: surfaceAlt,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          accent: accent,
          accentSubtle: accent.withValues(alpha: 0.15),
        ),
      ],
    );
  }
}

@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentSubtle,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentSubtle;

  @override
  AppColorExtension copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentSubtle,
  }) {
    return AppColorExtension(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentSubtle: accentSubtle ?? this.accentSubtle,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
    );
  }
}

extension ThemeX on BuildContext {
  AppColorExtension get colors =>
      Theme.of(this).extension<AppColorExtension>()!;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}
