import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/services/ads/ad_ids.dart';

/// A self-contained banner ad. Loads on mount, disposes on unmount, and
/// collapses to zero height if the ad fails to load (so screens never show
/// an empty grey gap where an ad didn't fill).
class AdBanner extends StatefulWidget {
  const AdBanner._({
    required this.adUnitId,
    required this.size,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  /// Standard 320x50 banner (primary unit).
  factory AdBanner.small({EdgeInsets? margin}) => AdBanner._(
        adUnitId: AdIds.bannerSmall,
        size: AdSize.banner,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      );

  /// Standard 320x50 banner (second unit — for a distinct slot on the same
  /// screen as [AdBanner.small]).
  factory AdBanner.small2({EdgeInsets? margin}) => AdBanner._(
        adUnitId: AdIds.bannerSmall2,
        size: AdSize.banner,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      );

  /// Medium rectangle (300x250) — the "large" in-content banner.
  factory AdBanner.large({EdgeInsets? margin}) => AdBanner._(
        adUnitId: AdIds.bannerLarge,
        size: AdSize.mediumRectangle,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 12),
      );

  final String adUnitId;
  final AdSize size;
  final EdgeInsets margin;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      width: widget.size.width.toDouble(),
      height: widget.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
