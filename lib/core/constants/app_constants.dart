class AppConstants {
  AppConstants._();

  // Animation durations
  static const controlsFadeMs = 200;
  static const controlsHideDelay = Duration(seconds: 3);
  static const pageTransitionMs = 300;

  // Player
  static const defaultSkipSeconds = 10;
  static const defaultPlaybackSpeed = 1.0;
  static const seekPreviewWidth = 120.0;
  static const seekPreviewHeight = 68.0;

  // UI sizing
  static const bottomNavHeight = 64.0;
  static const videoCardBorderRadius = 14.0;
  static const cardBorderRadius = 16.0;
  static const sheetBorderRadius = 24.0;

  // Grid
  static const gridCrossAxisCountPortrait = 2;
  static const gridCrossAxisCountLandscape = 3;
  static const gridChildAspectRatio = 0.72;

  // Storage keys
  static const keyThemeMode = 'theme_mode';
  static const keyAccentColor = 'accent_color';
  static const keyAccentColorSecondary = 'accent_color_secondary';
  static const keySkipDuration = 'skip_duration';
  static const keyDefaultZoom = 'default_zoom';
  static const keyBrightnessGesture = 'gesture_brightness';
  static const keyVolumeGesture = 'gesture_volume';
  static const keySeekGesture = 'gesture_seek';
  static const keyHaptics = 'haptics';
  static const keyHardwareDecode = 'hardware_decode';
  static const keyShowThumbnailOnSeek = 'seek_thumbnail';
  static const keySubtitleSize = 'subtitle_size';
  static const keySubtitleColor = 'subtitle_color';
  static const keySubtitleBgOpacity = 'subtitle_bg_opacity';
  static const keyResumePosition = 'resume_position';
  static const keyAutoPlayNext = 'auto_play_next';
  static const keyEqBands = 'eq_bands_v1';

  // Remote streaming
  static const pocketbaseUrl = 'https://novaplex-backend-production.up.railway.app';
  static const appLinksDomain = 'manzar-links.pages.dev';
  static const r2BucketUrl = 'https://pub-5d1f038f7ff34fb187e0e8bd49210a8b.r2.dev';
}
