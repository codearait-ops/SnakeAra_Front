import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Helper to parse DioException into user-friendly localized messages.
class ApiErrorParser {
  static String parseDioError(DioException e, {String? fallback}) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out';
    }

    if (e.response != null) {
      final response = e.response!;
      final data = response.data;

      if (data is Map) {
        // Validation Errors (422)
        if (response.statusCode == 422 && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.containsKey('username')) return 'err_username_taken'.tr;
          if (errors.containsKey('password')) return 'err_invalid_password'.tr;
          if (errors.containsKey('email')) {
            return (errors['email'] as List).first.toString();
          }

          if (errors.isNotEmpty) {
            final firstVal = errors.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              return firstVal.first.toString();
            }
          }
          return 'err_validation'.tr;
        }

        // Rate Limiting (429)
        if (response.statusCode == 429) {
          final retryAfter = response.headers.value('retry-after');
          if (retryAfter != null) {
            return 'Too many requests. Please wait $retryAfter seconds.';
          }
          return 'Too many requests. Please try again later.';
        }

        // Google Error
        if (response.statusCode == 400 && data['message'] != null) {
          return data['message'].toString();
        }

        // Map predefined server message strings
        final message = data['message']?.toString() ?? '';
        if (message.isNotEmpty) {
          final mapped = mapMessage(message, null);
          if (mapped != null) return mapped;
        }
      }

      if (response.statusCode == 401) return 'err_unauthenticated'.tr;
      if (response.statusCode == 403) return 'err_anti_cheat'.tr;
      if (response.statusCode == 500) return 'err_server_error'.tr;
    }

    return fallback ?? 'err_unknown'.tr;
  }

  static String? mapMessage(String msg, String? defaultVal) {
    const errorMessageMap = {
      'Invalid request (Anti-Cheat Triggered).': 'err_anti_cheat',
      'Invalid request (Anti-Cheat Triggered)': 'err_anti_cheat',
      'Anti-Cheat Triggered': 'err_anti_cheat',
      'Invalid username or password.': 'err_login_failed',
      'Invalid username or password': 'err_login_failed',
      'Unauthenticated.': 'err_unauthenticated',
      'Score updated successfully': 'msg_score_updated',
      'Failed to update server leaderboard': 'err_score_update_failed',
    };

    for (var entry in errorMessageMap.entries) {
      if (msg.contains(entry.key) || msg == entry.key) {
        return entry.value.tr;
      }
    }
    return defaultVal;
  }
}
