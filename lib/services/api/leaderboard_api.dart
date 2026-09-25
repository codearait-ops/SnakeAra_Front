import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/leaderboard/models/game_mode_leaderboard_entry.dart';
import '../../features/leaderboard/models/league_leaderboard_entry.dart';
import '../../features/leaderboard/models/online_leaderboard_entry.dart';
import '../../features/profile/models/universal_player_profile.dart';
import '../models/api_responses.dart';
import 'api_error_parser.dart';

/// Leaderboards (classic, per-mode, league) and public player profile API module.
class LeaderboardApi {
  final Dio _dio;

  LeaderboardApi(this._dio);

  /// Fetch Online Leaderboard for Classic Mode League
  Future<ApiResponse<List<OnlineLeaderboardEntry>>> getOnlineLeaderboard() async {
    try {
      final response = await _dio.get('/leaderboard/classic');
      if (response.statusCode == 200) {
        final bodyData = response.data;
        final dynamic dataField =
            bodyData['data'] ?? bodyData['leaderboard'] ?? bodyData;

        if (dataField is List) {
          final entries = <OnlineLeaderboardEntry>[];
          for (int i = 0; i < dataField.length; i++) {
            final item = dataField[i];
            if (item is Map<String, dynamic>) {
              entries.add(
                OnlineLeaderboardEntry.fromJson(item, fallbackRank: i + 1),
              );
            }
          }
          return ApiResponse.success(entries);
        }
      }
      return ApiResponse.error('Failed to load leaderboard from server');
    } on DioException catch (e) {
      return ApiResponse.error(
        'Could not connect to leaderboard server (${e.message})',
      );
    } catch (e) {
      return ApiResponse.error('Could not connect to leaderboard server ($e)');
    }
  }

  /// Fetch Online Leaderboard for a specific Game Mode
  Future<ApiResponse<List<OnlineLeaderboardEntry>>> getOnlineLeaderboardByMode(
    String modeId,
  ) async {
    String formattedMode = modeId;
    if (modeId == 'blindMemory') {
      formattedMode = 'blind_memory';
    } else if (modeId == 'laser') {
      formattedMode = 'laser_core';
    } else if (modeId == 'crabChase' || modeId == 'crab_chase') {
      formattedMode = 'crab';
    }

    try {
      final response = await _dio.get('/leaderboard/$formattedMode');
      if (response.statusCode == 200) {
        final bodyData = response.data;
        final dynamic dataField = bodyData is List
            ? bodyData
            : (bodyData is Map
                  ? (bodyData['data'] ??
                        bodyData['leaderboard'] ??
                        bodyData['scores'] ??
                        bodyData)
                  : null);

        if (dataField is List) {
          final entries = <OnlineLeaderboardEntry>[];
          for (int i = 0; i < dataField.length; i++) {
            final item = dataField[i];
            if (item is Map<String, dynamic>) {
              entries.add(
                OnlineLeaderboardEntry.fromJson(item, fallbackRank: i + 1),
              );
            } else if (item is Map) {
              entries.add(
                OnlineLeaderboardEntry.fromJson(
                  Map<String, dynamic>.from(item),
                  fallbackRank: i + 1,
                ),
              );
            }
          }
          return ApiResponse.success(entries);
        }
      }
      return ApiResponse.error('Failed to load $modeId leaderboard');
    } on DioException {
      return ApiResponse.error('Could not connect to leaderboard server');
    } catch (e) {
      return ApiResponse.error('Could not connect to leaderboard server ($e)');
    }
  }

  /// Fetch Leaderboard for Game Modes
  Future<ApiResponse<List<GameModeLeaderboardEntry>>> getModesLeaderboard(
    String mode,
  ) async {
    try {
      final response = await _dio.get('/leaderboard/$mode');
      debugPrint('[ApiService] getModesLeaderboard: /leaderboard/$mode -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final bodyData = response.data;
        final dynamic dataField = bodyData is List
            ? bodyData
            : (bodyData is Map
                  ? (bodyData['data'] ??
                        bodyData['leaderboard'] ??
                        bodyData['scores'] ??
                        bodyData)
                  : null);

        if (dataField is List) {
          final entries = <GameModeLeaderboardEntry>[];
          for (int i = 0; i < dataField.length; i++) {
            final item = dataField[i];
            if (item is Map<String, dynamic>) {
              entries.add(
                GameModeLeaderboardEntry.fromJson(item, fallbackRank: i + 1),
              );
            } else if (item is Map) {
              entries.add(
                GameModeLeaderboardEntry.fromJson(
                  Map<String, dynamic>.from(item),
                  fallbackRank: i + 1,
                ),
              );
            }
          }
          debugPrint(
            '[ApiService] getModesLeaderboard parsed ${entries.length} items. '
            'First entry: ${entries.firstOrNull?.username} avatar: ${entries.firstOrNull?.avatarUrl}',
          );
          return ApiResponse.success(entries);
        }
      }
      final msg = (response.data is Map)
          ? (response.data['message']?.toString())
          : null;
      return ApiResponse.error(msg ?? 'Failed to load leaderboard');
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch Weekly League Leaderboard
  Future<ApiResponse<List<LeagueLeaderboardEntry>>> getLeagueLeaderboard({
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/league/leaderboard?page=$page');
      final data = response.data;
      if (response.statusCode == 200 && data['status'] == 'success') {
        final List list = data['data'] ?? [];
        return ApiResponse.success(
          list.map((e) => LeagueLeaderboardEntry.fromJson(e)).toList(),
        );
      }
      return ApiResponse.error(
        data['message'] ?? 'Failed to load league leaderboard',
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch Universal Player Profile
  Future<ApiResponse<UniversalPlayerProfile>> getPlayerProfile(
    int userId,
  ) async {
    try {
      print(
        '--- [DEBUG] getPlayerProfile Request: /player/$userId/profile ---',
      );
      final response = await _dio.get('/player/$userId/profile');
      print(
        '--- [DEBUG] getPlayerProfile Response (${response.statusCode}): ${response.data} ---',
      );
      final data = response.data;
      if (response.statusCode == 200 && data['data'] != null) {
        return ApiResponse.success(
          UniversalPlayerProfile.fromJson(data['data']),
        );
      }
      return ApiResponse.error(
        data['message'] ?? 'Failed to load player profile',
      );
    } on DioException catch (e) {
      print('--- [DEBUG] getPlayerProfile DioException: ${e.message} ---');
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      print('--- [DEBUG] getPlayerProfile Error: $e ---');
      return ApiResponse.error(e.toString());
    }
  }
}
