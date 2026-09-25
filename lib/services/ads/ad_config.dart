/// Central configuration for AdMob and Tapsell ad units and credentials.
abstract class AdConfig {
  // ---------------------------------------------------------------------------
  // Google AdMob Configuration
  // ---------------------------------------------------------------------------
  static const String adMobAppId = 'ca-app-pub-1268698898067309~1457464547';
  static const String adMobBannerId = 'ca-app-pub-1268698898067309/8057250659';
  static const String adMobRewardedId = 'ca-app-pub-1268698898067309/7809838642';
  static const String adMobRewardedInterstitialId =
      'ca-app-pub-1268698898067309/5922041902';

  // ---------------------------------------------------------------------------
  // Tapsell Configuration
  // ---------------------------------------------------------------------------
  static const String tapsellAppKey =
      'cpgaaafsliptqsefjtptdhqogqhdqjhrntpbrfisptqifltdddjqadqlaitbthqgdatepd';
  static const String tapsellRewardedZoneId = '6ab5a71eda860d2c9f00d0b1';
  static const String tapsellBannerZoneId = '6ab5a7bd8670d80bfc879875';

  // ---------------------------------------------------------------------------
  // Waterfall Timing Configurations
  // ---------------------------------------------------------------------------
  /// Maximum duration to wait for AdMob to load an ad before falling back to Tapsell.
  /// Prevents indefinite stalls in restricted network environments.
  static const Duration adMobLoadTimeout = Duration(seconds: 8);

  /// Maximum duration to wait for Tapsell to request an ad.
  static const Duration tapsellRequestTimeout = Duration(seconds: 10);
}
