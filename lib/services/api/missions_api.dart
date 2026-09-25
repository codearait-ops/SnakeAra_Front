import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../app/core/utils/hmac_utils.dart';
import '../../features/daily_mission/models/daily_mission_model.dart';
import '../models/api_responses.dart';
import 'api_error_parser.dart';

/// Daily missions fetch, HMAC submit, and second-chance unlock API module.
class MissionsApi {
  final Dio _dio;

  MissionsApi(this._dio);

  /// Fetch today's active daily mission
  Future<ApiResponse<DailyMissionModel>> getDailyMission({
    String? token,
  }) async {
    try {
      debugPrint(
        '================= 🎯 [ApiService.getDailyMission] =================',
      );
      debugPrint(
        'URL: ${_dio.options.baseUrl}/daily-mission | Token: ${token != null && token.isNotEmpty ? 'Bearer ***' : 'none'}',
      );

      final options = Options(
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.get('/daily-mission', options: options);
      final data = response.data;

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Raw Data: $data');

      if (response.statusCode == 200 && data != null) {
        Map<String, dynamic> missionJson = {};
        if (data is Map<String, dynamic>) {
          // 1. Extract base mission object if nested
          if (data['mission'] is Map<String, dynamic>) {
            missionJson = Map<String, dynamic>.from(data['mission']);
          } else if (data['data'] is Map<String, dynamic>) {
            if (data['data']['mission'] is Map<String, dynamic>) {
              missionJson = Map<String, dynamic>.from(data['data']['mission']);
            } else {
              missionJson = Map<String, dynamic>.from(data['data']);
            }
          }

          // 2. Merge all top-level user participation fields so they take priority (excluding envelope metadata)
          data.forEach((key, value) {
            if (key != 'mission' &&
                key != 'data' &&
                key != 'status' &&
                key != 'message' &&
                key != 'server_time' &&
                value != null) {
              missionJson[key] = value;
            }
          });

          // 3. If data['data'] had extra user fields, merge them too
          if (data['data'] is Map<String, dynamic> &&
              data['data']['mission'] is Map<String, dynamic>) {
            (data['data'] as Map<String, dynamic>).forEach((key, value) {
              if (key != 'mission' &&
                  key != 'status' &&
                  key != 'message' &&
                  key != 'server_time' &&
                  value != null) {
                missionJson[key] = value;
              }
            });
          }
        }
        final model = DailyMissionModel.fromJson(missionJson);
        debugPrint(
          '🎯 Parsed DailyMissionModel -> ID: ${model.id} | Mode: ${model.gameMode} | Status: ${model.status} | Attempt: ${model.attemptNumber} | CanPlay: ${model.canPlay}',
        );
        debugPrint(
          '==================================================================',
        );
        return ApiResponse.success(model);
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to load today mission',
      );
    } on DioException catch (e) {
      debugPrint('--- [DEBUG] getDailyMission DioException ---');
      debugPrint('Message: ${e.message} | Response: ${e.response?.data}');
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      debugPrint('--- [DEBUG] getDailyMission Exception: $e ---');
      return ApiResponse.error(e.toString());
    }
  }

  /// Submit raw stat value for daily mission with HMAC signature
  Future<ApiResponse<DailyMissionSubmitResponse>> submitDailyMission({
    required int missionId,
    required int rawStatValue,
    required String userId,
    required String token,
    String? secretKey,
  }) async {
    try {
      // Client-side HMAC calculation: HMAC("mission:{dailyMissionId}:{rawStatValue}:{userId}", SecretKey)
      final signature = HmacUtils.generateDailyMissionSignature(
        missionId: missionId,
        rawStatValue: rawStatValue,
        userId: userId,
        customKey: secretKey,
      );
      final payloadString = 'mission:$missionId:$rawStatValue:$userId';

      debugPrint('--- [ApiService] submitDailyMission REQUEST ---');
      debugPrint('Endpoint: /daily-mission/submit');
      debugPrint(
        'daily_mission_id: $missionId | raw_stat_value: $rawStatValue | userId: $userId',
      );
      debugPrint('Payload: $payloadString | hmac_signature: $signature');

      final response = await _dio.post(
        '/daily-mission/submit',
        data: {
          'daily_mission_id': missionId,
          'raw_stat_value': rawStatValue,
          'hmac_signature': signature,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;
      debugPrint('--- [ApiService] submitDailyMission RESPONSE ---');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Data: $data');

      if (response.statusCode == 200 && data != null) {
        final Map<String, dynamic> submitMap =
            (data is Map<String, dynamic> &&
                data['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(data['data'])
            : (data is Map<String, dynamic>
                  ? Map<String, dynamic>.from(data)
                  : <String, dynamic>{});
        return ApiResponse.success(
          DailyMissionSubmitResponse.fromJson(submitMap),
        );
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to submit mission score',
      );
    } on DioException catch (e) {
      debugPrint('--- [ApiService] submitDailyMission DioException ---');
      debugPrint(
        'Status Code: ${e.response?.statusCode} | Data: ${e.response?.data}',
      );
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      debugPrint('--- [ApiService] submitDailyMission Exception: $e ---');
      return ApiResponse.error(e.toString());
    }
  }

  /// Unlock second attempt for daily mission via rewarded ad callback
  Future<ApiResponse<DailyMissionModel>> unlockSecondAttemptDailyMission({
    required int missionId,
    required String token,
  }) async {
    try {
      debugPrint(
        '--- [ApiService] unlockSecondAttemptDailyMission REQUEST ---',
      );
      debugPrint(
        'Endpoint: /daily-mission/unlock-second-attempt | daily_mission_id: $missionId',
      );

      final response = await _dio.post(
        '/daily-mission/unlock-second-attempt',
        data: {'daily_mission_id': missionId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;
      debugPrint(
        '--- [ApiService] unlockSecondAttemptDailyMission RESPONSE ---',
      );
      debugPrint('Status Code: ${response.statusCode} | Data: $data');

      if (response.statusCode == 200 && data != null) {
        final missionJson = data['mission'] ?? data['data'] ?? data;
        return ApiResponse.success(DailyMissionModel.fromJson(missionJson));
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to unlock second attempt',
      );
    } on DioException catch (e) {
      debugPrint(
        '--- [ApiService] unlockSecondAttemptDailyMission DioException: ${e.response?.data}',
      );
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      debugPrint(
        '--- [ApiService] unlockSecondAttemptDailyMission Exception: $e ---',
      );
      return ApiResponse.error(e.toString());
    }
  }
}
