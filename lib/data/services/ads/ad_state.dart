/// Shared coordination state between the full-screen ad managers
/// (interstitial, rewarded, app-open).
///
/// Its job is to stop the App Open ad from firing right after another
/// full-screen ad is dismissed: closing an interstitial/rewarded resumes the
/// Flutter activity, which fires AppLifecycleState.resumed — and without this
/// guard the App Open manager would treat that as a genuine app-foreground
/// and stack a second ad on top (a Google policy violation).
class AdState {
  AdState._();

  /// True while any full-screen ad is currently on screen.
  static bool isShowingFullScreenAd = false;

  /// When the last full-screen ad was dismissed. The App Open manager uses
  /// this to ignore the resume event caused by our own ad closing.
  static DateTime lastFullScreenAdDismissed =
      DateTime.fromMillisecondsSinceEpoch(0);

  /// A resume that lands within this window of an ad dismissal was almost
  /// certainly caused by that ad closing — not the user re-opening the app.
  static const resumeSuppressWindow = Duration(seconds: 3);

  static void onAdShown() {
    isShowingFullScreenAd = true;
  }

  static void onAdDismissed() {
    isShowingFullScreenAd = false;
    lastFullScreenAdDismissed = DateTime.now();
  }

  /// True if an App Open ad shown on resume right now would be stacking on
  /// top of / immediately after another full-screen ad.
  static bool get shouldSuppressAppOpenOnResume {
    if (isShowingFullScreenAd) return true;
    return DateTime.now().difference(lastFullScreenAdDismissed) <
        resumeSuppressWindow;
  }
}
