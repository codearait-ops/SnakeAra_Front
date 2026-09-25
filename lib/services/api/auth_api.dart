import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../../features/auth/models/user_model.dart';
import '../models/api_responses.dart';
import 'api_error_parser.dart';

/// Authentication and account management API module.
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// Register a new user account with preset avatar
  Future<ApiResponse<UserModel>> register({
    required String username,
    required String password,
    required String avatarId,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'username': username,
          'password': password,
          'avatar_id': avatarId,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['user'] != null) {
          final token = data['token']?.toString();
          final user = UserModel.fromJson(data['user'], fallbackToken: token);
          return ApiResponse.success(user);
        }
      }
      return ApiResponse.error('err_registration_failed'.tr);
    } on DioException catch (e) {
      debugPrint('[ApiService] register DioException: ${e.message}');
      debugPrint('[ApiService] Response data: ${e.response?.data}');
      debugPrint('[ApiService] Status code: ${e.response?.statusCode}');
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e, fallback: 'err_registration_failed'.tr),
      );
    } catch (e) {
      debugPrint('[ApiService] register Exception: $e');
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }

  /// Login with existing username & password
  Future<ApiResponse<UserModel>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'username': username, 'password': password},
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['user'] != null) {
          final token = data['token']?.toString();
          final user = UserModel.fromJson(data['user'], fallbackToken: token);
          return ApiResponse.success(user);
        }
      }
      return ApiResponse.error('err_login_failed'.tr);
    } on DioException catch (e) {
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e, fallback: 'err_login_failed'.tr),
      );
    } catch (e) {
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }

  /// Login with Google
  Future<ApiResponse<UserModel>> loginWithGoogle({
    required String idToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'id_token': idToken},
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['user'] != null) {
          final token = data['token']?.toString();
          final user = UserModel.fromJson(data['user'], fallbackToken: token);
          return ApiResponse.success(user);
        }
      }
      return ApiResponse.error('err_login_failed'.tr);
    } on DioException catch (e) {
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e, fallback: 'err_login_failed'.tr),
      );
    } catch (e) {
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }

  /// Forgot Password
  Future<ApiResponse<void>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );
      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message:
              data['message'] ??
              'If this email is registered, you will receive a new temporary password.',
        );
      }
      return ApiResponse.error('Error processing request');
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }

  /// Fetch User Profile (GET /profile)
  Future<ApiResponse<UserModel>> fetchUserProfile({
    required String token,
  }) async {
    try {
      print('--- [DEBUG] fetchUserProfile Request ---');
      print('URL: ${_dio.options.baseUrl}/profile');
      print('Token: $token');

      final response = await _dio.get(
        '/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('--- [DEBUG] fetchUserProfile Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      final data = response.data;
      if (response.statusCode == 200) {
        if (data['user'] != null || data['data'] != null) {
          final userJson = data['user'] ?? data['data'];
          final user = UserModel.fromJson(userJson, fallbackToken: token);
          return ApiResponse.success(user, message: data['message']);
        }
      }
      return ApiResponse.error('Error fetching profile');
    } on DioException catch (e) {
      print('--- [DEBUG] fetchUserProfile DioException ---');
      print('Message: ${e.message}');
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('--- [DEBUG] fetchUserProfile Exception: $e ---');
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }

  /// Update User Profile (Username, Avatar, Password, Email, Bio)
  Future<ApiResponse<UserModel>> updateProfile({
    required String token,
    String? username,
    String? avatarId,
    File? avatar,
    String? currentPassword,
    String? newPassword,
    String? email,
    String? bio,
  }) async {
    try {
      final payload = {
        if (username != null && username.isNotEmpty) 'username': username,
        if (avatarId != null && avatarId.isNotEmpty && avatarId != 'avatar_7')
          'avatar_id': avatarId,
        if (currentPassword != null && currentPassword.isNotEmpty)
          'current_password': currentPassword,
        if (newPassword != null && newPassword.isNotEmpty)
          'new_password': newPassword,
        if (email != null) 'email': email,
        if (bio != null) 'bio': bio,
      };

      FormData formData = FormData.fromMap(payload);
      if (avatar != null) {
        formData.files.add(
          MapEntry('avatar', await MultipartFile.fromFile(avatar.path)),
        );
      }

      print('--- [DEBUG] updateProfile Request ---');
      print('URL: ${_dio.options.baseUrl}/profile/update');
      print('Token: $token');
      print('Payload: $payload');
      if (avatar != null) {
        print('Avatar File: ${avatar.path}');
      }

      final response = await _dio.post(
        '/profile/update',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('--- [DEBUG] updateProfile Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      final data = response.data;
      if (response.statusCode == 200) {
        final userJson = data is Map
            ? (data['user'] ?? data['data'] ?? data)
            : {};
        final user =
            UserModel.fromJson(
              userJson is Map<String, dynamic> ? userJson : {},
              fallbackToken: token,
            ).copyWith(
              username: username,
              avatarId: avatarId,
              email: email,
              bio: bio,
            );
        return ApiResponse.success(
          user,
          message: data is Map ? data['message'] : null,
        );
      }
      return ApiResponse.error('Error updating profile');
    } on DioException catch (e) {
      print('--- [DEBUG] updateProfile DioException ---');
      print('Message: ${e.message}');
      print('Response Status: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      print('--- [DEBUG] updateProfile Exception: $e ---');
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }

  /// Change Password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          null,
          message: response.data['message'] ?? 'Password changed successfully.',
        );
      }
      return ApiResponse.error('Error changing password');
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error('Could not connect to server ($e)');
    }
  }
}
