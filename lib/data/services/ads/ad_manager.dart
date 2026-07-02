import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import 'ad_state.dart';

/// Central manager for full-screen ads (interstitial + rewarded).
///
/// Both formats are preloaded and kept ready so there's no visible delay when
/// they're shown. Every "show" path is fail-open: if an ad isn't ready (no
/// fill, offline, still loading) the gated action proceeds immediately rather
/// than blocking the user.
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  RewardedAd? _rewarded;
  bool _loadingRewarded = false;

  /// Counts tab switches so we can show an interstitial on every 2nd one
  /// (skip 1, show 1, skip 1, show 1 …).
  int _tabSwitchCount = 0;

  /// Guards against interstitials firing back-to-back when the user is
  /// rapidly tab-mashing — even if the cadence says "show".
  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);
  static const _interstitialCooldown = Duration(seconds: 15);

  /// Set true just before navigating to the fullscreen player from a shared-
  /// link video (which already showed a rewarded ad), so PlayerScreen skips
  /// its usual pre-roll interstitial exactly once.
  bool suppressNextVideoInterstitial = false;

  void init() {
    _loadInterstitial();
    _loadRewarded();
  }

  // ── Interstitial ───────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (_interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _loadingInterstitial = false;
          debugPrint('Interstitial failed to load: $err');
        },
      ),
    );
  }

  /// Show an interstitial if one is ready and the cooldown has elapsed, then
  /// always invoke [onDone]. [onShow] fires only if an ad actually appears
  /// (use it to pause video); [onDone] always fires (use it to resume/proceed).
  void showInterstitial({VoidCallback? onShow, VoidCallback? onDone}) {
    final ad = _interstitial;
    final now = DateTime.now();
    if (ad == null || now.difference(_lastInterstitial) < _interstitialCooldown) {
      _loadInterstitial();
      onDone?.call();
      return;
    }
    _interstitial = null;
    _lastInterstitial = now;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => AdState.onAdShown(),
      onAdDismissedFullScreenContent: (ad) {
        AdState.onAdDismissed();
        ad.dispose();
        _loadInterstitial();
        onDone?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        AdState.onAdDismissed();
        ad.dispose();
        _loadInterstitial();
        onDone?.call();
      },
    );
    onShow?.call();
    ad.show();
  }

  /// Tab-switch cadence: skip 1, show 1, skip 1, show 1 …
  void onTabSwitched({VoidCallback? onShow, VoidCallback? onDone}) {
    _tabSwitchCount++;
    if (_tabSwitchCount.isEven) {
      showInterstitial(onShow: onShow, onDone: onDone);
    } else {
      onDone?.call();
    }
  }

  // ── Rewarded ────────────────────────────────────────────────────────────────

  void _loadRewarded() {
    if (_rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          _loadingRewarded = false;
          debugPrint('Rewarded failed to load: $err');
        },
      ),
    );
  }

  bool get isRewardedReady => _rewarded != null;

  /// Show a rewarded ad. [onDone] always fires when the ad closes (or
  /// immediately if none is ready) so the caller is never left blocked —
  /// playback proceeds whether or not the reward was actually earned.
  void showRewarded({VoidCallback? onDone}) {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      onDone?.call();
      return;
    }
    _rewarded = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => AdState.onAdShown(),
      onAdDismissedFullScreenContent: (ad) {
        AdState.onAdDismissed();
        ad.dispose();
        _loadRewarded();
        onDone?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        AdState.onAdDismissed();
        ad.dispose();
        _loadRewarded();
        onDone?.call();
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) {});
  }
}
