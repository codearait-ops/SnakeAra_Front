import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'ad_provider.dart';

/// Provider for Google Mobile Ads (AdMob) Rewarded and Interstitial Ads.
class AdMobProvider implements AdNetworkProvider {
  @override
  String get providerName => 'Google AdMob';

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdMobProvider] Google Mobile Ads initialized successfully.');
    } catch (e) {
      debugPrint('[AdMobProvider] Initialization error: $e');
    }
  }

  @override
  Future<bool> showRewardedAd({
    required BuildContext context,
    VoidCallback? onBeforeShow,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('[AdMobProvider] Attempting to load Google AdMob Rewarded Ad...');
    final Completer<RewardedAd?> loadCompleter = Completer<RewardedAd?>();

    try {
      RewardedAd.load(
        adUnitId: AdConfig.adMobRewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            debugPrint('[AdMobProvider] AdMob Rewarded Ad loaded successfully.');
            if (!loadCompleter.isCompleted) {
              loadCompleter.complete(ad);
            } else {
              ad.dispose();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint(
              '[AdMobProvider] AdMob Rewarded load failed: code=${error.code}, domain=${error.domain}, message=${error.message}',
            );
            if (!loadCompleter.isCompleted) {
              loadCompleter.complete(null);
            }
          },
        ),
      );

      final RewardedAd? loadedAd = await loadCompleter.future.timeout(
        AdConfig.adMobLoadTimeout,
        onTimeout: () {
          debugPrint(
            '[AdMobProvider] AdMob Rewarded load timed out after ${AdConfig.adMobLoadTimeout.inSeconds}s.',
          );
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(null);
          }
          return null;
        },
      );

      if (loadedAd == null) {
        debugPrint('[AdMobProvider] No AdMob rewarded ad available.');
        return false;
      }

      final Completer<bool> showCompleter = Completer<bool>();
      bool earnedReward = false;

      loadedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('[AdMobProvider] AdMob rewarded ad opened in fullscreen.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint(
            '[AdMobProvider] AdMob rewarded ad closed. User earned reward: $earnedReward',
          );
          ad.dispose();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(earnedReward);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, AdError error) {
          debugPrint(
            '[AdMobProvider] AdMob rewarded ad failed to display: ${error.message}',
          );
          ad.dispose();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(false);
          }
        },
      );

      onBeforeShow?.call();

      await loadedAd.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint(
            '[AdMobProvider] onUserEarnedReward callback: ${reward.amount} ${reward.type}',
          );
          earnedReward = true;
        },
      );

      return await showCompleter.future;
    } catch (e) {
      debugPrint('[AdMobProvider] Unexpected exception in showRewardedAd: $e');
      return false;
    }
  }

  @override
  Future<bool> showInterstitialAd({
    required BuildContext context,
    VoidCallback? onBeforeShow,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('[AdMobProvider] Attempting to load Google AdMob Interstitial Ad...');
    final Completer<InterstitialAd?> loadCompleter =
        Completer<InterstitialAd?>();

    try {
      InterstitialAd.load(
        adUnitId: AdConfig.adMobInterstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('[AdMobProvider] AdMob Interstitial Ad loaded successfully.');
            if (!loadCompleter.isCompleted) {
              loadCompleter.complete(ad);
            } else {
              ad.dispose();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint(
              '[AdMobProvider] AdMob Interstitial load failed: code=${error.code}, domain=${error.domain}, message=${error.message}',
            );
            if (!loadCompleter.isCompleted) {
              loadCompleter.complete(null);
            }
          },
        ),
      );

      final InterstitialAd? loadedAd = await loadCompleter.future.timeout(
        AdConfig.adMobLoadTimeout,
        onTimeout: () {
          debugPrint(
            '[AdMobProvider] AdMob Interstitial load timed out after ${AdConfig.adMobLoadTimeout.inSeconds}s.',
          );
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(null);
          }
          return null;
        },
      );

      if (loadedAd == null) {
        debugPrint('[AdMobProvider] No AdMob interstitial ad available.');
        return false;
      }

      final Completer<bool> showCompleter = Completer<bool>();

      loadedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('[AdMobProvider] AdMob Interstitial opened in fullscreen.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('[AdMobProvider] AdMob Interstitial closed normally.');
          ad.dispose();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(true);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, AdError error) {
          debugPrint(
            '[AdMobProvider] AdMob Interstitial failed to display: ${error.message}',
          );
          ad.dispose();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(false);
          }
        },
      );

      onBeforeShow?.call();
      await loadedAd.show();
      return await showCompleter.future;
    } catch (e) {
      debugPrint('[AdMobProvider] Unexpected exception in showInterstitialAd: $e');
      return false;
    }
  }
}
