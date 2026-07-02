import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Loads and shows App Open ads — on cold start and when the app is brought
/// back to the foreground from the background.
///
/// Register [AppOpenAdManager.instance] as a [WidgetsBindingObserver] once
/// (done in main.dart) and call [loadAd] after MobileAds init.
class AppOpenAdManager with WidgetsBindingObserver {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _ad;
  bool _isShowing = false;
  bool _loading = false;
  DateTime? _loadedAt;

  /// App Open ads expire ~4 hours after load; don't show a stale one.
  static const _maxCacheAge = Duration(hours: 4);

  /// Cooldown so a quick app-switch flurry doesn't show an ad every time.
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  static const _resumeCooldown = Duration(minutes: 4);

  bool get _isAdAvailable {
    if (_ad == null || _loadedAt == null) return false;
    return DateTime.now().difference(_loadedAt!) < _maxCacheAge;
  }

  void loadAd() {
    if (_loading || _isAdAvailable) return;
    _loading = true;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _loading = false;
          debugPrint('App open ad failed to load: $err');
        },
      ),
    );
  }

  /// Show the ad if one is ready. [respectCooldown] is true for resume-driven
  /// shows so we don't spam on every foreground; false for the cold-start show.
  void showIfAvailable({bool respectCooldown = true}) {
    if (_isShowing) return;
    if (respectCooldown &&
        DateTime.now().difference(_lastShown) < _resumeCooldown) {
      return;
    }
    if (!_isAdAvailable) {
      loadAd();
      return;
    }

    final ad = _ad!;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowing = true;
        _lastShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        ad.dispose();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _isShowing = false;
        ad.dispose();
        loadAd();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showIfAvailable();
    }
  }
}
