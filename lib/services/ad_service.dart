import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

class AdService {
  // Your Android App Key
  static const String androidAppKey = '6109553';
  
  // IMPORTANT: Replace these with your REAL Ad Unit IDs from LevelPlay Dashboard
  // Real ads will only show if these IDs are correct and active in the dashboard.
  static const String rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID'; 
  static const String interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';

  static String get appKey => androidAppKey;

  static LevelPlayRewardedAd? _rewardedAd;
  static LevelPlayInterstitialAd? _interstitialAd;
  static Function? _onRewardCallback;

  static Future<void> init() async {
    try {
      // 1. Production Configuration: No test mode flags set here.
      // Make sure 'is_test_suite' is NOT enabled in production.
      await LevelPlay.setMetaData({'is_test_suite': ['disable']});
      
      LevelPlayInitRequest initRequest = LevelPlayInitRequest.builder(appKey).build();

      // 2. Initialize with Listener
      await LevelPlay.init(
        initRequest: initRequest,
        initListener: MyLevelPlayInitListener(),
      );
      
      print('Unity LevelPlay (Production) Initialization Started...');
    } catch (e) {
      print('Unity LevelPlay Initialization Failed: $e');
    }
  }

  static void setupAds() {
    _rewardedAd = LevelPlayRewardedAd(adUnitId: rewardedAdUnitId);
    _interstitialAd = LevelPlayInterstitialAd(adUnitId: interstitialAdUnitId);

    _rewardedAd?.setListener(MyRewardedAdListener());
    _interstitialAd?.setListener(MyInterstitialAdListener());

    loadAllAds();
  }

  static void loadAllAds() {
    _rewardedAd?.loadAd();
    _interstitialAd?.loadAd();
  }

  static void showInterstitial() async {
    bool isReady = await _interstitialAd?.isAdReady() ?? false;
    if (isReady) {
      _interstitialAd?.showAd();
    } else {
      print('Interstitial Ad not ready, loading...');
      _interstitialAd?.loadAd();
    }
  }

  static void showRewarded(Function onCompleteReward) async {
    _onRewardCallback = onCompleteReward;
    bool isReady = await _rewardedAd?.isAdReady() ?? false;
    if (isReady) {
      _rewardedAd?.showAd();
    } else {
      print('Rewarded Ad not ready, loading...');
      _rewardedAd?.loadAd();
    }
  }

  static void handleReward() {
    if (_onRewardCallback != null) {
      _onRewardCallback!();
      _onRewardCallback = null;
    }
  }
}

// --- Listeners ---

class MyLevelPlayInitListener extends LevelPlayInitListener {
  @override
  void onInitFailed(LevelPlayInitError error) {
    print('Unity LevelPlay Init Failed: ${error.errorMessage}');
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    print('Unity LevelPlay Init Success (Production Mode)!');
    AdService.setupAds();
  }
}

class MyRewardedAdListener extends LevelPlayRewardedAdListener {
  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) => print('Rewarded Ad Loaded');
  @override
  void onAdLoadFailed(LevelPlayAdError error) => print('Rewarded Ad Load Failed: ${error.errorMessage}');
  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) => print('Rewarded Ad Displayed');
  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) => print('Rewarded Ad Display Failed');
  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    print('Rewarded Ad Closed');
    AdService._rewardedAd?.loadAd();
  }
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) => print('Rewarded Ad Clicked');
  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    print('User earned reward: ${reward.name}');
    AdService.handleReward();
  }
  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

class MyInterstitialAdListener extends LevelPlayInterstitialAdListener {
  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) => print('Interstitial Ad Loaded');
  @override
  void onAdLoadFailed(LevelPlayAdError error) => print('Interstitial Ad Load Failed: ${error.errorMessage}');
  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) => print('Interstitial Ad Displayed');
  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) => print('Interstitial Ad Display Failed');
  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    print('Interstitial Ad Closed');
    AdService._interstitialAd?.loadAd();
  }
  @override
  void onAdClicked(LevelPlayAdInfo adInfo) => print('Interstitial Ad Clicked');
  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}
