import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import 'ad_config.dart';
import 'ad_provider.dart';

/// Provider for Tapsell Plus Rewarded and Interstitial Video Ads.
class TapsellProvider implements AdNetworkProvider {
  @override
  String get providerName => 'Tapsell Plus';

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await TapsellPlus.instance.initialize(AdConfig.tapsellAppKey);
      _isInitialized = true;
      debugPrint('[TapsellProvider] Tapsell Plus initialized successfully.');
    } catch (e) {
      debugPrint('[TapsellProvider] Initialization error: $e');
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

    debugPrint('[TapsellProvider] Requesting Tapsell Rewarded Video Ad...');
    try {
      final String responseId = await TapsellPlus.instance
          .requestRewardedVideoAd(AdConfig.tapsellRewardedZoneId)
          .timeout(
            AdConfig.tapsellRequestTimeout,
            onTimeout: () {
              debugPrint(
                '[TapsellProvider] Tapsell rewarded request timed out after ${AdConfig.tapsellRequestTimeout.inSeconds}s.',
              );
              return '';
            },
          );

      if (responseId.isEmpty) {
        debugPrint('[TapsellProvider] No ad available or responseId was empty.');
        return false;
      }

      debugPrint(
        '[TapsellProvider] Tapsell ad ready with responseId: $responseId. Displaying...',
      );

      // Dismiss loading dialog before displaying the ad
      onBeforeShow?.call();

      final Completer<bool> showCompleter = Completer<bool>();
      bool earnedReward = false;

      await TapsellPlus.instance.showRewardedVideoAd(
        responseId,
        onOpened: (map) {
          debugPrint('[TapsellProvider] Tapsell rewarded ad opened: $map');
          onBeforeShow?.call();
        },
        onRewarded: (map) {
          debugPrint(
            '[TapsellProvider] Tapsell onRewarded callback triggered: $map',
          );
          earnedReward = true;
        },
        onClosed: (map) {
          debugPrint(
            '[TapsellProvider] Tapsell rewarded ad closed. Reward status: $earnedReward',
          );
          onBeforeShow?.call();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(earnedReward);
          }
        },
        onError: (map) {
          debugPrint('[TapsellProvider] Tapsell rewarded ad show error: $map');
          onBeforeShow?.call();
          if (!showCompleter.isCompleted) {
            showCompleter.complete(false);
          }
        },
      );

      return await showCompleter.future;
    } catch (e) {
      debugPrint('[TapsellProvider] Exception showing Tapsell ad: $e');
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

    debugPrint('[TapsellProvider] Requesting Tapsell Interstitial Video Ad...');
    try {
      final String responseId = await TapsellPlus.instance
          .requestInterstitialAd(AdConfig.tapsellInterstitialZoneId)
          .timeout(
            AdConfig.tapsellRequestTimeout,
            onTimeout: () {
              debugPrint(
                '[TapsellProvider] Tapsell interstitial request timed out after ${AdConfig.tapsellRequestTimeout.inSeconds}s.',
              );
              return '';
            },
          );

      if (responseId.isEmpty) {
        debugPrint('[TapsellProvider] No interstitial ad available or responseId was empty.');
        return false;
      }

      debugPrint(
        '[TapsellProvider] Tapsell interstitial ready with responseId: $responseId. Displaying...',
      );

      onBeforeShow?.call();

      final Completer<bool> showCompleter = Completer<bool>();

      await TapsellPlus.instance.showInterstitialAd(
        responseId,
        onOpened: (map) {
          debugPrint('[TapsellProvider] Tapsell Interstitial opened: $map');
        },
        onClosed: (map) {
          debugPrint('[TapsellProvider] Tapsell Interstitial closed.');
          if (!showCompleter.isCompleted) {
            showCompleter.complete(true);
          }
        },
        onError: (map) {
          debugPrint('[TapsellProvider] Tapsell Interstitial show error: $map');
          if (!showCompleter.isCompleted) {
            showCompleter.complete(false);
          }
        },
      );

      return await showCompleter.future;
    } catch (e) {
      debugPrint('[TapsellProvider] Exception showing Tapsell interstitial ad: $e');
      return false;
    }
  }
}
