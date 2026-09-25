import 'package:dio/dio.dart';
import '../../features/menu/models/home_dashboard_model.dart';
import '../../features/profile/models/profile_full_model.dart';
import '../models/api_responses.dart';
import 'api_error_parser.dart';

/// Home dashboard, full profile summary, and player stats API module.
class DashboardApi {
  final Dio _dio;

  DashboardApi(this._dio);

  /// Fetch aggregated Home dashboard data (GET /home/dashboard)
  Future<ApiResponse<HomeDashboardResponse>> getHomeDashboard({
    String? token,
  }) async {
    try {
      print('--- [DEBUG] getHomeDashboard Request ---');
      print(
        'URL: ${_dio.options.baseUrl}/home/dashboard | Token: ${token != null && token.isNotEmpty ? 'Bearer ***' : 'none'}',
      );

      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.get('/home/dashboard', options: options);

      print('--- [DEBUG] getHomeDashboard Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final res = HomeDashboardResponse.fromJson(
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : Map<String, dynamic>.from(response.data as Map),
        );
        return ApiResponse.success(res, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        response.data?['message'] ?? 'Failed to load home dashboard',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      print('--- [DEBUG] getHomeDashboard DioException ---');
      print('Message: ${e.message}');
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch full user profile & stats in a single call (GET /profile/me/full)
  Future<ApiResponse<ProfileMeFullResponse>> getProfileMeFull({
    required String token,
  }) async {
    try {
      print('--- [DEBUG] getProfileMeFull Request ---');
      print('URL: ${_dio.options.baseUrl}/profile/me/full');

      final response = await _dio.get(
        '/profile/me/full',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('--- [DEBUG] getProfileMeFull Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final res = ProfileMeFullResponse.fromJson(
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : Map<String, dynamic>.from(response.data as Map),
          token: token,
        );
        return ApiResponse.success(res, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        response.data?['message'] ?? 'Failed to load full profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      print('--- [DEBUG] getProfileMeFull DioException ---');
      print('Message: ${e.message}');
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get My Stats (GET /my-stats)
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyStats(
    String token,
  ) async {
    try {
      final response = await _dio.get(
        '/my-stats',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final bodyData = response.data;
      if (response.statusCode == 200 && bodyData['status'] == 'success') {
        if (bodyData['data'] is List) {
          final list = (bodyData['data'] as List).cast<Map<String, dynamic>>();
          return ApiResponse.success(list);
        }
      }
      return ApiResponse.error('Failed to load stats');
    } on DioException catch (e) {
      return ApiResponse.error('Could not connect to server (${e.message})');
    } catch (e) {
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }
}
