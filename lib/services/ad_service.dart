import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// Ceylonix Unity Ads Manager — Rewarded Ads Only
/// ================================================
/// Game ID: 6109553
/// Rewarded: Rewarded_Android
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String _gameId = '6109553';
  static const String rewardedId = 'Rewarded_Android';

  bool _isInitialized = false;
  bool _isRewardedLoaded = false;

  bool get isInitialized => _isInitialized;

  /// Initialize Unity Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[AdService] 🚀 Starting initialization...');

    UnityAds.init(
      gameId: _gameId,
      testMode: false,
      onComplete: () {
        _isInitialized = true;
        debugPrint('[AdService] ✅ Unity Ads Initialized');
        loadRewarded();
      },
      onFailed: (error, message) {
        _isInitialized = false;
        debugPrint('[AdService] ❌ Init Failed: $error — $message');
        Future.delayed(const Duration(seconds: 30), initialize);
      },
    );
  }

  void setPremiumStatus(bool hasTime) {
    debugPrint('[AdService] 💎 Premium status: $hasTime');
  }

  void loadRewarded() {
    if (!_isInitialized) return;

    debugPrint('[AdService] 🔄 Loading Rewarded...');
    UnityAds.load(
      placementId: rewardedId,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        debugPrint('[AdService] ✅ Rewarded Ad Loaded');
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        debugPrint('[AdService] ❌ Load Failed ($error): $message');
        Future.delayed(const Duration(seconds: 15), loadRewarded);
      },
    );
  }

  bool isRewardedReady() {
    return _isInitialized && _isRewardedLoaded;
  }

  void showRewarded({
    required VoidCallback onRewardEarned,
    VoidCallback? onFailed,
  }) {
    if (!isRewardedReady()) {
      debugPrint('[AdService] ⚠️ Rewarded ad not ready');
      loadRewarded();
      onFailed?.call();
      return;
    }

    _isRewardedLoaded = false;

    UnityAds.showVideoAd(
      placementId: rewardedId,
      onStart: (placementId) => debugPrint('[AdService] ▶️ Rewarded Started'),
      onComplete: (placementId) {
        debugPrint('[AdService] 🎁 Reward Earned!');
        onRewardEarned();
        loadRewarded();
      },
      onSkipped: (placementId) {
        debugPrint('[AdService] ⏭️ Rewarded Skipped');
        loadRewarded();
      },
      onFailed: (placementId, error, message) {
        debugPrint('[AdService] ❌ Show Failed: $error');
        onFailed?.call();
        loadRewarded();
      },
    );
  }
}
