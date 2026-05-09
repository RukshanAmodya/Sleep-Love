import 'dart:io';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdService {
  static const String androidGameId = '6109553';
  static const String iosGameId = '6109552';

  static String get gameId => Platform.isAndroid ? androidGameId : iosGameId;

  static String get rewardedPlacementId => Platform.isAndroid ? 'Rewarded_Android' : 'Rewarded_iOS';
  static String get interstitialPlacementId => Platform.isAndroid ? 'Interstitial_Android' : 'Interstitial_iOS';
  static String get bannerPlacementId => Platform.isAndroid ? 'Banner_Android' : 'Banner_iOS';

  static Future<void> init() async {
    await UnityAds.init(
      gameId: gameId,
      testMode: true, // Set to false for production
      onComplete: () {
        print('Unity Ads Initialization Complete');
        loadAllAds();
      },
      onFailed: (error, message) => print('Unity Ads Initialization Failed: $error $message'),
    );
  }

  static void loadAllAds() {
    loadRewarded();
    loadInterstitial();
  }

  static void loadRewarded() {
    UnityAds.load(
      placementId: rewardedPlacementId,
      onComplete: (placementId) => print('Rewarded Ad Loaded: $placementId'),
      onFailed: (placementId, error, message) => print('Rewarded Ad Load Failed: $error $message'),
    );
  }

  static void loadInterstitial() {
    UnityAds.load(
      placementId: interstitialPlacementId,
      onComplete: (placementId) => print('Interstitial Ad Loaded: $placementId'),
      onFailed: (placementId, error, message) => print('Interstitial Ad Load Failed: $error $message'),
    );
  }

  static void showInterstitial() {
    UnityAds.showVideoAd(
      placementId: interstitialPlacementId,
      onComplete: (placementId) {
        print('Interstitial Ad Complete');
        loadInterstitial(); // Reload for next time
      },
      onFailed: (placementId, error, message) {
        print('Interstitial Ad Failed: $error $message');
        loadInterstitial();
      },
    );
  }

  static void showRewarded(Function onCompleteReward) {
    UnityAds.showVideoAd(
      placementId: rewardedPlacementId,
      onComplete: (placementId) {
        onCompleteReward();
        print('Rewarded Ad Complete');
        loadRewarded(); // Reload for next time
      },
      onFailed: (placementId, error, message) {
        print('Rewarded Ad Failed: $error $message');
        loadRewarded();
      },
    );
  }
}
