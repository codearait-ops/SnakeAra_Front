import 'package:flutter/material.dart';

/// Abstract contract for any Ad Network Provider in SnakeAra.
abstract class AdNetworkProvider {
  /// Name of the ad network (e.g. "Google AdMob", "Tapsell Plus").
  String get providerName;

  /// Initializes the underlying SDK.
  Future<void> initialize();

  /// Attempts to load and show a rewarded video ad.
  ///
  /// [onBeforeShow] is executed right after the ad is loaded and ready,
  /// immediately before presenting the fullscreen ad to the user (e.g., to dismiss loading indicators).
  ///
  /// Returns `true` if the user completed viewing the ad and earned the reward.
  /// Returns `false` if loading/showing failed, was cancelled, or was skipped.
  Future<bool> showRewardedAd({
    required BuildContext context,
    VoidCallback? onBeforeShow,
  });
}
