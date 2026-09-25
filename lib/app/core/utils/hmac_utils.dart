import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';

/// Centralized utility for computing HMAC-SHA256 signatures for anti-cheat verification.
class HmacUtils {
  /// Reassembles the split key fragments at point of use (interim hardening).
  static String getSecurityKey() {
    return '$kSecurityTokenPrefix$kSecurityTokenMidfix$kSecurityTokenSuffix';
  }

  /// Calculates HMAC-SHA256 signature using the standard score payload formula:
  /// HMAC("{game_mode}:{value}:{userId}", key)
  static String generateScoreSignature({
    required String gameMode,
    required int value,
    required String userId,
    String? customKey,
  }) {
    final payload = '$gameMode:$value:$userId';
    return calculateHmac(payload, customKey: customKey);
  }

  /// Calculates HMAC-SHA256 signature for daily missions:
  /// HMAC("mission:{dailyMissionId}:{rawStatValue}:{userId}", key)
  static String generateDailyMissionSignature({
    required int missionId,
    required int rawStatValue,
    required String userId,
    String? customKey,
  }) {
    final payload = 'mission:$missionId:$rawStatValue:$userId';
    return calculateHmac(payload, customKey: customKey);
  }

  /// Raw HMAC-SHA256 hex digest generator.
  static String calculateHmac(String payload, {String? customKey}) {
    final key = customKey ?? getSecurityKey();
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(payload)).toString();
  }
}
