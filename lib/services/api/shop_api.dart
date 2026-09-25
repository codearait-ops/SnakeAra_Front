import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../features/cosmetics/models/cosmetics_models.dart';
import '../../features/wallet/models/wallet_models.dart';
import '../models/api_responses.dart';
import 'api_error_parser.dart';

/// Shop catalog, cosmetics, skins, and purchase API module.
class ShopApi {
  final Dio _dio;

  ShopApi(this._dio);

  /// Fetch items available in the shop with user_balance
  Future<ApiResponse<ShopCatalogResponse>> getShopCatalog({
    String? token,
  }) async {
    try {
      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      final response = await _dio.get('/shop/catalog', options: options);
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        if (data is List) {
          final items = data
              .map(
                (e) =>
                    ShopItemModel.fromJson(e is Map<String, dynamic> ? e : {}),
              )
              .toList();
          return ApiResponse.success(
            ShopCatalogResponse(items: items),
            statusCode: response.statusCode,
          );
        } else if (data is Map<String, dynamic>) {
          return ApiResponse.success(
            ShopCatalogResponse.fromJson(data),
            statusCode: response.statusCode,
          );
        }
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to load shop',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch full cosmetics catalog from GET /shop
  Future<ApiResponse<CosmeticsCatalogResponse>> getShopCosmetics({
    String? token,
  }) async {
    try {
      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      final response = await _dio.get('/shop', options: options);
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final parsed = CosmeticsCatalogResponse.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map),
        );
        return ApiResponse.success(parsed, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to load cosmetics catalog',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        ApiErrorParser.parseDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Purchase a shop item (skin, theme, avatar) via POST /shop/purchase
  Future<ApiResponse<ShopPurchaseResponse>> purchaseShopItem({
    required dynamic itemId,
    String? itemType,
    required String token,
  }) async {
    try {
      final parsedInt = int.tryParse(itemId.toString());
      final dynamic payloadId = parsedInt ?? itemId;

      final Map<String, dynamic> body = {
        'item_id': payloadId,
      };
      if (itemType != null && itemType.isNotEmpty) {
        body['item_type'] = itemType;
      }

      final response = await _dio.post(
        '/shop/purchase',
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return ApiResponse.success(
          ShopPurchaseResponse.fromJson(
            data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map),
          ),
          statusCode: response.statusCode,
        );
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to complete cosmetics purchase',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String? customMsg;
      if (statusCode == 409) {
        customMsg = 'item_already_owned'.tr;
      } else if (statusCode == 422 || statusCode == 400) {
        customMsg = 'insufficient_coins_shop'.tr;
      }
      return ApiResponse.error(
        customMsg ?? ApiErrorParser.parseDioError(e),
        statusCode: statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Purchase a cosmetic theme or avatar via POST /shop/purchase
  Future<ApiResponse<ShopPurchaseResponse>> purchaseCosmeticsItem({
    required dynamic itemId,
    required String itemType,
    required String token,
  }) =>
      purchaseShopItem(
        itemId: itemId,
        itemType: itemType,
        token: token,
      );
}
