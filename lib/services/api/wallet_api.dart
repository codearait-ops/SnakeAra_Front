import 'package:dio/dio.dart';
import '../../features/wallet/models/wallet_models.dart';
import '../models/api_responses.dart';
import 'api_error_parser.dart';

/// Wallet, transactions, ad reward verification, and welcome bonus API module.
class WalletApi {
  final Dio _dio;

  WalletApi(this._dio);

  /// Fetch full wallet data including coin balance and ad reward cooldown/limits
  Future<ApiResponse<WalletData>> getWallet({required String token}) async {
    try {
      final response = await _dio.get(
        '/wallet',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final walletData = WalletData.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        return ApiResponse.success(walletData);
      }
      return ApiResponse.error(data?['message'] ?? 'Failed to fetch wallet');
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Server-side verification for rewarded ad viewing (POST /api/ads/verify-reward)
  Future<ApiResponse<Map<String, dynamic>>> verifyAdReward({
    required String placement,
    required String token,
    String? rewardToken,
  }) async {
    try {
      final response = await _dio.post(
        '/ads/verify-reward',
        data: {
          'placement': placement,
          'purpose': placement,
          if (rewardToken != null && rewardToken.isNotEmpty)
            'reward_token': rewardToken,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return ApiResponse.success(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
          message: data['message']?.toString(),
        );
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to verify ad reward',
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch user coin balance
  Future<ApiResponse<int>> getWalletBalance({required String token}) async {
    try {
      final response = await _dio.get(
        '/wallet/balance',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final rawBalance =
            data['balance'] ?? data['coins'] ?? data['data']?['balance'] ?? 0;
        final balance = rawBalance is num
            ? rawBalance.toInt()
            : (int.tryParse(rawBalance.toString()) ?? 0);
        return ApiResponse.success(balance);
      }
      return ApiResponse.error(data?['message'] ?? 'Failed to fetch balance');
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch user coin transaction history (paginated)
  Future<ApiResponse<List<CoinTransactionModel>>> getCoinTransactions({
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get(
        '/wallet/transactions',
        queryParameters: {'page': page, 'per_page': perPage, 'limit': perPage},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          if (data['transactions'] is List) {
            rawList = data['transactions'];
          } else if (data['transactions'] is Map &&
              data['transactions']['data'] is List) {
            rawList = data['transactions']['data'];
          } else if (data['data'] is List) {
            rawList = data['data'];
          } else if (data['data'] is Map && data['data']['data'] is List) {
            rawList = data['data']['data'];
          }
        }
        return ApiResponse.success(
          rawList
              .map(
                (e) => CoinTransactionModel.fromJson(
                  e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
        );
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to fetch transactions',
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Claim welcome bonus for new users (POST /wallet/claim-welcome-bonus)
  Future<ApiResponse<WelcomeBonusResponse>> claimWelcomeBonus({
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/wallet/claim-welcome-bonus',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final bonusData = WelcomeBonusResponse.fromJson(
          data is Map<String, dynamic>
              ? data
              : Map<String, dynamic>.from(data as Map),
        );
        return ApiResponse.success(bonusData);
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to claim welcome bonus',
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiErrorParser.parseDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
