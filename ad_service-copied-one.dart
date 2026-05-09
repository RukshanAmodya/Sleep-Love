import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ceylonix Unity Ads Manager — Singleton Pattern
/// ================================================
/// Game ID: 6089450
/// Interstitial: Interstitial_Android
/// Rewarded: Rewarded_Android
/// Banner: Banner_Android
class AdService {
  // --- Singleton Pattern ---
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // --- Constants ---
  static const String _gameId = '6089450';
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
  static const int _minSecondsBetweenInterstitials = 60; // Minimum 60 seconds between interstitials
  static const int _maxInterstitialsPerSession = 10;

  // --- VPN Toggle Counter (show every 2nd toggle) ---
  int _vpnToggleCount = 0;

  // --- Rewarded Cooldown ---
  DateTime? _lastRewardedShown;
  static const int _rewardedCooldownSeconds = 30; // 30 seconds wait between ads

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isPremiumUser => _isPremiumUser;

  /// Initialize Unity Ads SDK
  /// Splash screen එකේදී call කරන්න
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[AdService] 🚀 Starting initialization...');

    // Check if user is premium
    await _checkPremiumStatus();

    if (_isPremiumUser) {
      debugPrint('[AdService] 💎 Premium user detected — Ads DISABLED');
      // Uncomment the line below to reset premium status for testing:
      // await setPremiumStatus(false); 
      return;
    }

    UnityAds.init(
      gameId: _gameId,
      testMode: false, // 🚀 LIVE Mode Enabled
      onComplete: () {
        _isInitialized = true;
        debugPrint('[AdService] ✅ Unity Ads Initialized Successfully');
        // Pre-load ads so they're ready instantly
        loadInterstitial();
        loadRewarded();
      },
      onFailed: (error, message) {
        _isInitialized = false;
        debugPrint('[AdService] ❌ Unity Ads Init Failed: $error — $message');
      },
    );
  }

  /// Check if user has active paid packages (premium = no ads)
  Future<void> _checkPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremiumUser = prefs.getBool('is_premium_user') ?? false;
    } catch (e) {
      _isPremiumUser = false;
    }
  }

  /// Update user premium status (call when user buys a package)
  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremiumUser = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', isPremium);
  }

  // ══════════════════════════════════════════════════
  //                INTERSTITIAL ADS
  // ══════════════════════════════════════════════════

  /// Pre-load interstitial ad
  void loadInterstitial() {
    if (_isPremiumUser || !_isInitialized) return;

    UnityAds.load(
      placementId: interstitialId,
      onComplete: (placementId) {
        _isInterstitialLoaded = true;
        debugPrint('[AdService] ✅ Interstitial Loaded');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialLoaded = false;
        debugPrint('[AdService] ❌ Interstitial Load Failed: $error — $message');
        // Retry after 30 seconds
        Future.delayed(const Duration(seconds: 30), loadInterstitial);
      },
    );
  }

  /// Show interstitial ad with frequency cap
  void showInterstitial({VoidCallback? onComplete}) {
    if (_isPremiumUser || !_isInitialized || !_isInterstitialLoaded) {
      onComplete?.call();
      return;
    }

    // Frequency cap check
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
      onStart: (placementId) {
        debugPrint('[AdService] ▶️ Interstitial Started');
      },
      onComplete: (placementId) {
        debugPrint('[AdService] ✅ Interstitial Complete');
        onComplete?.call();
        loadInterstitial(); // Pre-load next one
      },
      onSkipped: (placementId) {
        debugPrint('[AdService] ⏭️ Interstitial Skipped');
        onComplete?.call();
        loadInterstitial();
      },
      onFailed: (placementId, error, message) {
        debugPrint('[AdService] ❌ Interstitial Show Failed: $error');
        onComplete?.call();
        loadInterstitial();
      },
    );
  }

  /// Check frequency cap for interstitials
  bool _canShowInterstitial() {
    if (_interstitialCount >= _maxInterstitialsPerSession) return false;
    if (_lastInterstitialShown == null) return true;
    final diff = DateTime.now().difference(_lastInterstitialShown!).inSeconds;
    return diff >= _minSecondsBetweenInterstitials;
  }

  /// VPN Toggle specific — show every 2nd toggle
  void showInterstitialOnVpnToggle({VoidCallback? onComplete}) {
    _vpnToggleCount++;
    if (_vpnToggleCount % 2 == 0) {
      showInterstitial(onComplete: onComplete);
    } else {
      onComplete?.call();
    }
  }

  // ══════════════════════════════════════════════════
  //                REWARDED VIDEO ADS
  // ══════════════════════════════════════════════════

  /// Pre-load rewarded video
  void loadRewarded() {
    if (_isPremiumUser || !_isInitialized) return;

    UnityAds.load(
      placementId: rewardedId,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        debugPrint('[AdService] ✅ Rewarded Video Loaded');
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        debugPrint('[AdService] ❌ Rewarded Load Failed: $error — $message');
        Future.delayed(const Duration(seconds: 30), loadRewarded);
      },
    );
  }

  /// Check if a rewarded video is ready to show
  bool isRewardedReady() {
    if (_isPremiumUser || !_isInitialized || !_isRewardedLoaded) return false;
    
    if (_lastRewardedShown != null) {
      final diff = DateTime.now().difference(_lastRewardedShown!).inSeconds;
      if (diff < _rewardedCooldownSeconds) return false;
    }

    return true;
  }

  /// Get remaining cooldown for rewarded ads
  int getRewardedCooldown() {
    if (_lastRewardedShown == null) return 0;
    final diff = DateTime.now().difference(_lastRewardedShown!).inSeconds;
    final remaining = _rewardedCooldownSeconds - diff;
    return remaining > 0 ? remaining : 0;
  }

  /// Show rewarded video ad
  /// [onRewardEarned] — call this when user completes watching the full ad
  void showRewarded({
    required VoidCallback onRewardEarned,
    VoidCallback? onSkipped,
    VoidCallback? onFailed,
  }) {
    if (!isRewardedReady()) {
      onFailed?.call();
      return;
    }

    _isRewardedLoaded = false;
    _lastRewardedShown = DateTime.now();

    UnityAds.showVideoAd(
      placementId: rewardedId,
      onStart: (placementId) {
        debugPrint('[AdService] ▶️ Rewarded Video Started');
      },
      onComplete: (placementId) {
        debugPrint('[AdService] 🎁 Rewarded Video Complete — REWARD EARNED');
        onRewardEarned();
        loadRewarded(); // Pre-load next one
      },
      onSkipped: (placementId) {
        debugPrint('[AdService] ⏭️ Rewarded Video Skipped — NO REWARD');
        onSkipped?.call();
        loadRewarded();
      },
      onFailed: (placementId, error, message) {
        debugPrint('[AdService] ❌ Rewarded Show Failed: $error');
        onFailed?.call();
        loadRewarded();
      },
    );
  }

  // ══════════════════════════════════════════════════
  //                BANNER ADS
  // ══════════════════════════════════════════════════

  /// Returns a Banner Ad Widget — place this in your UI tree
  /// Premium users get an empty SizedBox (no ad)
  Widget getBannerWidget({double height = 50}) {
    if (_isPremiumUser) {
      return const SizedBox.shrink();
    }

    if (!_isInitialized) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Ad Service Initializing...',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: UnityBannerAd(
        placementId: bannerId,
        onLoad: (placementId) {
          debugPrint('[AdService] ✅ Banner Loaded: $placementId');
        },
        onShown: (placementId) {
          debugPrint('[AdService] 📦 Banner Shown: $placementId');
        },
        onClick: (placementId) {
          debugPrint('[AdService] 👆 Banner Clicked: $placementId');
        },
        onFailed: (placementId, error, message) {
          debugPrint('[AdService] ❌ Banner Failed: $error — $message');
        },
      ),
    );
  }

  /// Returns a native-looking banner for inline placement (server list, etc.)
  Widget getInlineBannerWidget() {
    if (_isPremiumUser || !_isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 50,
              child: UnityBannerAd(
                placementId: bannerId,
                onLoad: (placementId) => debugPrint('[AdService] Inline Banner Loaded'),
                onFailed: (placementId, error, message) =>
                    debugPrint('[AdService] Inline Banner Failed: $error'),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 4),
              child: const Text(
                'Sponsored',
                style: TextStyle(
                  fontSize: 8,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
