import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// Sleep Love Unity Ads Manager — Singleton Pattern
/// Optimized based on Ceylonix Unity Ads Manager
class AdService {
  // --- Singleton Pattern ---
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // --- Constants ---
  // Using the provided Android Game ID
  static const String _gameId = '6109553';
  
  static const String interstitialId = 'Interstitial_Android';
  static const String rewardedId = 'Rewarded_Android';
  static const String bannerId = 'Banner_Android';

  // --- State ---
  bool _isInitialized = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  
  // Frequency Capping
  DateTime? _lastAdTime;
  static const int _adIntervalSeconds = 60;

  /// Initialize Unity Ads
  Future<void> initialize() async {
    if (_isInitialized) return;

    await UnityAds.init(
      gameId: _gameId,
      testMode: false, // Set to true for testing, false for production
      onComplete: () {
        print('Unity Ads Initialization Complete');
        _isInitialized = true;
        _loadAllAds();
      },
      onFailed: (error, message) {
        print('Unity Ads Initialization Failed: $error - $message');
        _isInitialized = false;
      },
    );
  }

  void _loadAllAds() {
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    UnityAds.load(
      placementId: interstitialId,
      onComplete: (placementId) {
        print('Interstitial Ad Loaded: $placementId');
        _isInterstitialLoaded = true;
      },
      onFailed: (placementId, error, message) {
        print('Interstitial Ad Load Failed: $error - $message');
        _isInterstitialLoaded = false;
      },
    );
  }

  void _loadRewarded() {
    UnityAds.load(
      placementId: rewardedId,
      onComplete: (placementId) {
        print('Rewarded Ad Loaded: $placementId');
        _isRewardedLoaded = true;
      },
      onFailed: (placementId, error, message) {
        print('Rewarded Ad Load Failed: $error - $message');
        _isRewardedLoaded = false;
      },
    );
  }

  /// Show Interstitial Ad with Frequency Capping
  void showInterstitial({VoidCallback? onComplete}) {
    if (!_isInitialized || !_isInterstitialLoaded) {
      print('Interstitial not ready, loading...');
      _loadInterstitial();
      onComplete?.call();
      return;
    }

    // Frequency Capping check
    if (_lastAdTime != null) {
      final difference = DateTime.now().difference(_lastAdTime!).inSeconds;
      if (difference < _adIntervalSeconds) {
        print('Ad skipped due to frequency capping ($difference/$_adIntervalSeconds)');
        onComplete?.call();
        return;
      }
    }

    UnityAds.showVideoAd(
      placementId: interstitialId,
      onStart: (placementId) => print('Interstitial Ad Started: $placementId'),
      onClick: (placementId) => print('Interstitial Ad Clicked: $placementId'),
      onSkipped: (placementId) {
        print('Interstitial Ad Skipped: $placementId');
        _lastAdTime = DateTime.now();
        _isInterstitialLoaded = false;
        _loadInterstitial();
        onComplete?.call();
      },
      onComplete: (placementId) {
        print('Interstitial Ad Complete: $placementId');
        _lastAdTime = DateTime.now();
        _isInterstitialLoaded = false;
        _loadInterstitial();
        onComplete?.call();
      },
      onFailed: (placementId, error, message) {
        print('Interstitial Ad Show Failed: $error - $message');
        _isInterstitialLoaded = false;
        _loadInterstitial();
        onComplete?.call();
      },
    );
  }

  /// Show Rewarded Ad
  void showRewarded({required VoidCallback onRewardEarned, VoidCallback? onFailed}) {
    if (!_isInitialized || !_isRewardedLoaded) {
      print('Rewarded Ad not ready, loading...');
      _loadRewarded();
      onFailed?.call();
      return;
    }

    UnityAds.showVideoAd(
      placementId: rewardedId,
      onStart: (placementId) => print('Rewarded Ad Started: $placementId'),
      onClick: (placementId) => print('Rewarded Ad Clicked: $placementId'),
      onSkipped: (placementId) {
        print('Rewarded Ad Skipped: $placementId');
        _isRewardedLoaded = false;
        _loadRewarded();
        onFailed?.call();
      },
      onComplete: (placementId) {
        print('Rewarded Ad Complete: $placementId');
        _isRewardedLoaded = false;
        _loadRewarded();
        onRewardEarned();
      },
      onFailed: (placementId, error, message) {
        print('Rewarded Ad Show Failed: $error - $message');
        _isRewardedLoaded = false;
        _loadRewarded();
        onFailed?.call();
      },
    );
  }

  /// Get Banner Ad Widget
  Widget getBannerWidget() {
    return UnityBannerAd(
      placementId: bannerId,
      onLoad: (placementId) => print('Banner Loaded: $placementId'),
      onClick: (placementId) => print('Banner Clicked: $placementId'),
      onFailed: (placementId, error, message) => print('Banner Failed: $error - $message'),
    );
  }
}
