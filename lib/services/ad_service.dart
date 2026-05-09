import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// Ceylonix Unity Ads Manager — Rewarded Ads Only
/// ================================================
/// Game ID: 6089450
/// Rewarded: Rewarded_Android
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String _gameId = '6089450';
  static const String rewardedId = 'Rewarded_Android';

  bool _isInitialized = false;
  bool _isRewardedLoaded = false;
  int _retryCount = 0;

  bool get isInitialized => _isInitialized;

  /// Initialize Unity Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[AdService] 🚀 Initializing with Game ID: $_gameId');

    UnityAds.init(
      gameId: _gameId,
      testMode: false,
      onComplete: () {
        _isInitialized = true;
        debugPrint('[AdService] ✅ Initialized');
        loadRewarded();
      },
      onFailed: (error, message) {
        _isInitialized = false;
        debugPrint('[AdService] ❌ Init Failed: $error — $message');
        Future.delayed(const Duration(seconds: 10), initialize);
      },
    );
  }

  void setPremiumStatus(bool hasTime) {
    debugPrint('[AdService] 💎 Has Time: $hasTime');
  }

  void loadRewarded() {
    if (!_isInitialized) return;

    debugPrint('[AdService] 🔄 Loading Rewarded Ad...');
    UnityAds.load(
      placementId: rewardedId,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        _retryCount = 0;
        debugPrint('[AdService] ✅ Ad Ready');
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        _retryCount++;
        debugPrint('[AdService] ❌ Load Failed ($_retryCount): $message');
        // Faster retry for the first few times, then slow down
        int delay = _retryCount < 5 ? 5 : 15;
        Future.delayed(Duration(seconds: delay), loadRewarded);
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
      debugPrint('[AdService] ⚠️ Ad not ready. Current state: Initialized=$_isInitialized, Loaded=$_isRewardedLoaded');
      loadRewarded(); // Try loading again
      onFailed?.call();
      return;
    }

    _isRewardedLoaded = false;

    UnityAds.showVideoAd(
      placementId: rewardedId,
      onStart: (placementId) => debugPrint('[AdService] ▶️ Ad Started'),
      onComplete: (placementId) {
        debugPrint('[AdService] 🎁 Reward Granted!');
        onRewardEarned();
        // Delay slightly before loading next ad to avoid network conflicts
        Future.delayed(const Duration(seconds: 2), loadRewarded);
      },
      onSkipped: (placementId) {
        debugPrint('[AdService] ⏭️ Ad Skipped');
        Future.delayed(const Duration(seconds: 2), loadRewarded);
      },
      onFailed: (placementId, error, message) {
        debugPrint('[AdService] ❌ Show Failed: $error');
        onFailed?.call();
        loadRewarded();
      },
    );
  }
}
