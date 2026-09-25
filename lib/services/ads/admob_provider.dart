import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'ad_provider.dart';

/// Provider for Google Mobile Ads (AdMob) Rewarded Ads.
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
              // Timed out previously, dispose of the late ad
              ad.dispose();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint(
              '[AdMobProvider] AdMob load failed: code=${error.code}, domain=${error.domain}, message=${error.message}',
            );
            if (!loadCompleter.isCompleted) {
              loadCompleter.complete(null);
            }
          },
        ),
      );

      // Wait with timeout to prevent blocking when Google is restricted/unreachable
      final RewardedAd? loadedAd = await loadCompleter.future.timeout(
        AdConfig.adMobLoadTimeout,
        onTimeout: () {
          debugPrint(
            '[AdMobProvider] AdMob load timed out after ${AdConfig.adMobLoadTimeout.inSeconds}s.',
          );
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(null);
          }
          return null;
        },
      );

      if (loadedAd == null) {
        debugPrint('[AdMobProvider] No AdMob ad available.');
        return false;
      }

      final Completer<bool> showCompleter = Completer<bool>();
      bool earnedReward = false;

      loadedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('[AdMobProvider] AdMob ad opened in fullscreen.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint(
            '[AdMobProvider] AdMob ad closed. User earned reward: $earnedReward',
          );
          ad.dispose();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(earnedReward);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, AdError error) {
          debugPrint('[AdMobProvider] AdMob failed to display: ${error.message}');
          ad.dispose();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(false);
          }
        },
      );

      // Dismiss any loading dialog before presenting the fullscreen ad
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
}
