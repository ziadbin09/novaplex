import 'dart:io';

/// Central registry of AdMob ad unit IDs.
///
/// IMPORTANT: [useTestAds] MUST be true during development. Tapping your own
/// live ads (or even loading them repeatedly on your own device) is "invalid
/// activity" and can get your entire AdMob account suspended — which kills
/// every ad unit at once, not just one. Google's official test unit IDs
/// (used below when [useTestAds] is true) always fill and are safe to tap.
///
/// Flip [useTestAds] to false ONLY for the final Play Store release build.
class AdIds {
  AdIds._();

  /// Set to false for the production/Play Store build. Leave true for all
  /// testing on real devices and emulators.
  static const bool useTestAds = true;

  // ── Live AdMob unit IDs (Manzar) ──────────────────────────────────────────
  static const _appOpen = 'ca-app-pub-2083629374546177/7060893053';
  static const _interstitial = 'ca-app-pub-2083629374546177/2191709754';
  static const _rewarded = 'ca-app-pub-2083629374546177/9687056394';
  static const _bannerSmall = 'ca-app-pub-2083629374546177/5858166603';
  static const _bannerSmall2 = 'ca-app-pub-2083629374546177/7581813406';
  static const _bannerLarge = 'ca-app-pub-2083629374546177/7485645870';

  // ── Google's official test unit IDs (Android) ─────────────────────────────
  static const _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';

  static bool get _android => Platform.isAndroid;

  static String get appOpen =>
      useTestAds || !_android ? _testAppOpen : _appOpen;

  static String get interstitial =>
      useTestAds || !_android ? _testInterstitial : _interstitial;

  static String get rewarded =>
      useTestAds || !_android ? _testRewarded : _rewarded;

  /// Primary small (320x50) banner unit.
  static String get bannerSmall =>
      useTestAds || !_android ? _testBanner : _bannerSmall;

  /// Second small (320x50) banner unit — lets two small banners on the same
  /// screen use distinct units (better fill + reporting).
  static String get bannerSmall2 =>
      useTestAds || !_android ? _testBanner : _bannerSmall2;

  /// Large / medium-rectangle (300x250) banner unit.
  static String get bannerLarge =>
      useTestAds || !_android ? _testBanner : _bannerLarge;
}
