import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// Sleep Love Unity Ads Manager — Singleton Pattern
/// Optimized for the project's user state
class AdService {
  // --- Singleton Pattern ---
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // --- Constants ---
  static const String _gameId = '6109553';
  static const String interstitialId = 'Interstitial_Android';
  static const String rewardedId = 'Rewarded_Android';
  static const String bannerId = 'Banner_Android';

  // --- State ---
  bool _isInitialized = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  // --- Frequency Cap ---
  DateTime? _lastInterstitialShown;
  static const int _minSecondsBetweenInterstitials = 45; // Reduced for better UX

  // --- Getters ---
  bool get isInitialized => _isInitialized;

  /// Initialize Unity Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[AdService] 🚀 Initializing Unity Ads...');

    UnityAds.init(
      gameId: _gameId,
      testMode: false, // 🚀 LIVE Mode
      onComplete: () {
        _isInitialized = true;
        debugPrint('[AdService] ✅ Unity Ads Initialized');
        loadInterstitial();
        loadRewarded();
      },
      onFailed: (error, message) {
        _isInitialized = false;
        debugPrint('[AdService] ❌ Unity Ads Init Failed: $error — $message');
      },
    );
  }

  // ══════════════════════════════════════════════════
  //                INTERSTITIAL ADS
  // ══════════════════════════════════════════════════

  void loadInterstitial() {
    if (!_isInitialized) return;

    UnityAds.load(
      placementId: interstitialId,
      onComplete: (placementId) {
        _isInterstitialLoaded = true;
        debugPrint('[AdService] ✅ Interstitial Loaded');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialLoaded = false;
        debugPrint('[AdService] ❌ Interstitial Load Failed: $error — $message');
        Future.delayed(const Duration(seconds: 30), loadInterstitial);
      },
    );
  }

  void showInterstitial({VoidCallback? onComplete, bool isPro = false}) {
    // If user is Pro, don't show ad and just call onComplete
    if (isPro) {
      onComplete?.call();
      return;
    }

    if (!_isInitialized || !_isInterstitialLoaded) {
      debugPrint('[AdService] ⚠️ Interstitial not ready');
      onComplete?.call();
      return;
    }

    // Frequency cap check
    if (_lastInterstitialShown != null) {
      final diff = DateTime.now().difference(_lastInterstitialShown!).inSeconds;
      if (diff < _minSecondsBetweenInterstitials) {
        onComplete?.call();
        return;
      }
    }

    _isInterstitialLoaded = false;
    _lastInterstitialShown = DateTime.now();

    UnityAds.showVideoAd(
      placementId: interstitialId,
      onComplete: (placementId) {
        onComplete?.call();
        loadInterstitial();
      },
      onSkipped: (placementId) {
        onComplete?.call();
        loadInterstitial();
      },
      onFailed: (placementId, error, message) {
        onComplete?.call();
        loadInterstitial();
      },
    );
  }

  // ══════════════════════════════════════════════════
  //                REWARDED VIDEO ADS
  // ══════════════════════════════════════════════════

  void loadRewarded() {
    if (!_isInitialized) return;

    UnityAds.load(
      placementId: rewardedId,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        debugPrint('[AdService] ✅ Rewarded Video Loaded');
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        debugPrint('[AdService] ❌ Rewarded Load Failed: $error — $message');
        Future.delayed(const Duration(seconds: 15), loadRewarded);
      },
    );
  }

  void showRewarded({
    required VoidCallback onRewardEarned,
    VoidCallback? onFailed,
    bool isPro = false,
  }) {
    // If user is already Pro, they don't need to watch ads for time
    if (isPro) {
      onRewardEarned();
      return;
    }

    if (!_isInitialized || !_isRewardedLoaded) {
      debugPrint('[AdService] ⚠️ Rewarded Ad not ready');
      onFailed?.call();
      return;
    }

    _isRewardedLoaded = false;

    UnityAds.showVideoAd(
      placementId: rewardedId,
      onComplete: (placementId) {
        onRewardEarned();
        loadRewarded();
      },
      onSkipped: (placementId) {
        loadRewarded();
      },
      onFailed: (placementId, error, message) {
        onFailed?.call();
        loadRewarded();
      },
    );
  }

  // ══════════════════════════════════════════════════
  //                BANNER ADS
  // ══════════════════════════════════════════════════

  Widget getBannerWidget({bool isPro = false}) {
    if (isPro || !_isInitialized) return const SizedBox.shrink();

    return Container(
      height: 50,
      alignment: Alignment.center,
      child: UnityBannerAd(
        placementId: bannerId,
        onLoad: (placementId) => debugPrint('[AdService] Banner Loaded'),
        onFailed: (placementId, error, message) => debugPrint('[AdService] Banner Failed'),
      ),
    );
  }
}
