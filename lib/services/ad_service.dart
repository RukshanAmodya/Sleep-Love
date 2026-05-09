import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ceylonix Unity Ads Manager — Singleton Pattern
/// ================================================
/// Game ID: 6109553
/// Interstitial: Interstitial_Android
/// Rewarded: Rewarded_Android
/// Banner: Banner_Android
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
  bool _isPremiumUser = false;

  // --- Frequency Cap ---
  DateTime? _lastInterstitialShown;
  int _interstitialCount = 0;
  static const int _minSecondsBetweenInterstitials = 60; 
  static const int _maxInterstitialsPerSession = 10;

  // --- VPN Toggle Counter (show every 2nd toggle) ---
  int _vpnToggleCount = 0;

  // --- Rewarded Cooldown ---
  DateTime? _lastRewardedShown;
  static const int _rewardedCooldownSeconds = 30;

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isPremiumUser => _isPremiumUser;

  /// Initialize Unity Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[AdService] 🚀 Starting initialization...');

    await _checkPremiumStatus();

    if (_isPremiumUser) {
      debugPrint('[AdService] 💎 Premium user detected — Ads DISABLED');
      return;
    }

    UnityAds.init(
      gameId: _gameId,
      testMode: false, // 🚀 Keep false for Real Ads, set true ONLY for testing
      onComplete: () {
        _isInitialized = true;
        debugPrint('[AdService] ✅ Unity Ads Initialized Successfully');
        loadInterstitial();
        loadRewarded();
      },
      onFailed: (error, message) {
        _isInitialized = false;
        debugPrint('[AdService] ❌ Unity Ads Init Failed: $error — $message');
        // Retry init after 30 seconds
        Future.delayed(const Duration(seconds: 30), initialize);
      },
    );
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPermanentPro = prefs.getBool('is_pro_permanent') ?? false;
      final secondsRemaining = prefs.getInt('premium_seconds_local') ?? 0;
      _isPremiumUser = isPermanentPro || secondsRemaining > 0;
      debugPrint('[AdService] 🔍 Checked Premium: $_isPremiumUser');
    } catch (e) {
      _isPremiumUser = false;
    }
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremiumUser = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', isPremium);
    debugPrint('[AdService] 💎 Premium status manually updated to: $isPremium');
  }

  // ══════════════════════════════════════════════════
  //                INTERSTITIAL ADS
  // ══════════════════════════════════════════════════

  void loadInterstitial() {
    if (_isPremiumUser || !_isInitialized) return;

    debugPrint('[AdService] 🔄 Loading Interstitial...');
    UnityAds.load(
      placementId: interstitialId,
      onComplete: (placementId) {
        _isInterstitialLoaded = true;
        debugPrint('[AdService] ✅ Interstitial Loaded');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialLoaded = false;
        debugPrint('[AdService] ❌ Interstitial Load Failed ($error): $message');
        // Retry after 15 seconds for network errors
        Future.delayed(const Duration(seconds: 15), loadInterstitial);
      },
    );
  }

  void showInterstitial({VoidCallback? onComplete}) {
    if (_isPremiumUser) {
      onComplete?.call();
      return;
    }

    if (!_isInitialized || !_isInterstitialLoaded) {
      debugPrint('[AdService] ⚠️ Interstitial not ready, calling onComplete. Loaded: $_isInterstitialLoaded');
      if (!_isInterstitialLoaded) loadInterstitial();
      onComplete?.call();
      return;
    }

    if (!_canShowInterstitial()) {
      debugPrint('[AdService] ⏳ Interstitial frequency cap — skipping');
      onComplete?.call();
      return;
    }

    _isInterstitialLoaded = false;
    _lastInterstitialShown = DateTime.now();
    _interstitialCount++;

    UnityAds.showVideoAd(
      placementId: interstitialId,
      onStart: (placementId) => debugPrint('[AdService] ▶️ Interstitial Started'),
      onComplete: (placementId) {
        debugPrint('[AdService] ✅ Interstitial Complete');
        onComplete?.call();
        loadInterstitial();
      },
      onSkipped: (placementId) {
        debugPrint('[AdService] ⏭️ Interstitial Skipped');
        onComplete?.call();
        loadInterstitial();
      },
      onFailed: (placementId, error, message) {
        debugPrint('[AdService] ❌ Interstitial Show Failed: $error - $message');
        onComplete?.call();
        loadInterstitial();
      },
    );
  }

  bool _canShowInterstitial() {
    if (_interstitialCount >= _maxInterstitialsPerSession) return false;
    if (_lastInterstitialShown == null) return true;
    final diff = DateTime.now().difference(_lastInterstitialShown!).inSeconds;
    return diff >= _minSecondsBetweenInterstitials;
  }

  // ══════════════════════════════════════════════════
  //                REWARDED VIDEO ADS
  // ══════════════════════════════════════════════════

  void loadRewarded() {
    if (_isPremiumUser || !_isInitialized) return;

    debugPrint('[AdService] 🔄 Loading Rewarded...');
    UnityAds.load(
      placementId: rewardedId,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        debugPrint('[AdService] ✅ Rewarded Video Loaded');
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        debugPrint('[AdService] ❌ Rewarded Load Failed ($error): $message');
        // Retry after 15 seconds
        Future.delayed(const Duration(seconds: 15), loadRewarded);
      },
    );
  }

  bool isRewardedReady() {
    if (_isPremiumUser || !_isInitialized || !_isRewardedLoaded) return false;
    
    if (_lastRewardedShown != null) {
      final diff = DateTime.now().difference(_lastRewardedShown!).inSeconds;
      if (diff < _rewardedCooldownSeconds) return false;
    }

    return true;
  }

  void showRewarded({
    required VoidCallback onRewardEarned,
    VoidCallback? onSkipped,
    VoidCallback? onFailed,
  }) {
    if (!isRewardedReady()) {
      debugPrint('[AdService] ⚠️ Rewarded ad not ready for show. Loaded: $_isRewardedLoaded');
      if (!_isRewardedLoaded) loadRewarded();
      onFailed?.call();
      return;
    }

    _isRewardedLoaded = false;
    _lastRewardedShown = DateTime.now();

    UnityAds.showVideoAd(
      placementId: rewardedId,
      onStart: (placementId) => debugPrint('[AdService] ▶️ Rewarded Video Started'),
      onComplete: (placementId) {
        debugPrint('[AdService] 🎁 Rewarded Video Complete — REWARD EARNED');
        onRewardEarned();
        loadRewarded();
      },
      onSkipped: (placementId) {
        debugPrint('[AdService] ⏭️ Rewarded Video Skipped — NO REWARD');
        onSkipped?.call();
        loadRewarded();
      },
      onFailed: (placementId, error, message) {
        debugPrint('[AdService] ❌ Rewarded Show Failed: $error - $message');
        onFailed?.call();
        loadRewarded();
      },
    );
  }

  // ══════════════════════════════════════════════════
  //                BANNER ADS
  // ══════════════════════════════════════════════════

  Widget getBannerWidget({double height = 50}) {
    if (_isPremiumUser) return const SizedBox.shrink();

    if (!_isInitialized) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Initializing...', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: UnityBannerAd(
        placementId: bannerId,
        onLoad: (placementId) => debugPrint('[AdService] ✅ Banner Loaded: $placementId'),
        onFailed: (placementId, error, message) => debugPrint('[AdService] ❌ Banner Failed: $error — $message'),
      ),
    );
  }
}
