import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import 'ad_state.dart';

/// Loads and shows App Open ads — once on cold start, and again when the app
/// is genuinely brought back to the foreground from the background.
///
/// Register [AppOpenAdManager.instance] as a [WidgetsBindingObserver] once
/// (done in main.dart) and call [loadColdStartAd] after MobileAds init.
class AppOpenAdManager with WidgetsBindingObserver {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _ad;
  bool _isShowing = false;
  bool _loading = false;
  DateTime? _loadedAt;

  /// When set, the ad is shown as soon as it finishes loading (used for the
  /// cold-start ad, which usually isn't ready the instant the app launches).
  bool _showWhenLoaded = false;

  /// App Open ads expire ~4 hours after load; don't show a stale one.
  static const _maxCacheAge = Duration(hours: 4);

  /// Cooldown so a quick app-switch flurry doesn't show an ad every time.
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  static const _resumeCooldown = Duration(minutes: 4);

  bool get _isAdAvailable {
    if (_ad == null || _loadedAt == null) return false;
    return DateTime.now().difference(_loadedAt!) < _maxCacheAge;
  }

  /// Load the launch ad and show it the moment it's ready.
  void loadColdStartAd() {
    _showWhenLoaded = true;
    _load();
  }

  void _load() {
    if (_loading || _isAdAvailable) {
      if (_showWhenLoaded && _isAdAvailable) {
        _showWhenLoaded = false;
        _show(respectCooldown: false);
      }
      return;
    }
    _loading = true;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
          if (_showWhenLoaded) {
            _showWhenLoaded = false;
            _show(respectCooldown: false);
          }
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _loading = false;
          _showWhenLoaded = false;
          debugPrint('App open ad failed to load: $err');
        },
      ),
    );
  }

  void _show({required bool respectCooldown}) {
    if (_isShowing) return;
    // Never stack on top of / right after another full-screen ad.
    if (respectCooldown && AdState.shouldSuppressAppOpenOnResume) return;
    if (respectCooldown &&
        DateTime.now().difference(_lastShown) < _resumeCooldown) {
      return;
    }
    if (!_isAdAvailable) {
      _load();
      return;
    }

    final ad = _ad!;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowing = true;
        _lastShown = DateTime.now();
        AdState.onAdShown();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        AdState.onAdDismissed();
        ad.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _isShowing = false;
        AdState.onAdDismissed();
        ad.dispose();
        _load();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _show(respectCooldown: true);
    }
  }
}
