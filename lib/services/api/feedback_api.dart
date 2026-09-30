import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../models/api_responses.dart';
import 'api_error_parser.dart';

/// Feedback and support API delegate.
class FeedbackApi {
  final Dio _dio;

  FeedbackApi(this._dio);

  /// Submits user feedback or suggestion to the server (POST /feedback).
  Future<ApiResponse<Map<String, dynamic>>> submitFeedback({
    required String message,
    String? type,
    String? contact,
    String? token,
    String? appVersion,
    String? deviceInfo,
  }) async {
    try {
      final payload = <String, dynamic>{
        'message': message.trim(),
        'type': type ?? 'suggestion',
        if (contact != null && contact.trim().isNotEmpty)
          'contact': contact.trim(),
        if (appVersion != null && appVersion.isNotEmpty)
          'app_version': appVersion,
        if (deviceInfo != null && deviceInfo.isNotEmpty)
          'device_info': deviceInfo,
      };

      final options = Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.post(
        '/feedback',
        data: payload,
        options: options,
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final serverMessage = data is Map ? data['message']?.toString() : null;
        return ApiResponse.success(
          data is Map<String, dynamic> ? data : {'success': true},
          message: serverMessage ?? 'feedback_success'.tr,
        );
      }

      return ApiResponse.error('err_feedback_failed'.tr);
    } on DioException catch (e) {
      debugPrint('[FeedbackApi] submitFeedback DioException: ${e.message}');
      debugPrint('[FeedbackApi] Response: ${e.response?.data}');
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e, fallback: 'err_feedback_failed'.tr),
      );
    } catch (e) {
      debugPrint('[FeedbackApi] submitFeedback Exception: $e');
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }
}
