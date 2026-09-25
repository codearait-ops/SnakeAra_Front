import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../models/cosmetics_models.dart';
import '../../wallet/models/wallet_models.dart';

/// Repository managing network interactions for the Cosmetics System (Themes + Avatars).
class CosmeticsRepository {
  final ApiService _api;

  CosmeticsRepository({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  /// Fetches cosmetics owned by the player from GET /home/dashboard
  Future<({List<CosmeticTheme> themes, List<CosmeticAvatar> avatars})>
      getDashboardCosmetics({String? token}) async {
    final response = await _api.getHomeDashboard(token: token);
    if (response.isSuccess && response.data != null) {
      return (
        themes: response.data!.availableThemes,
        avatars: response.data!.availableAvatars,
      );
    }
    return (themes: <CosmeticTheme>[], avatars: <CosmeticAvatar>[]);
  }

  /// Fetches the complete cosmetics catalog from GET /shop
  /// Ignores skins array and only processes themes and avatars.
  Future<CosmeticsCatalogResponse?> getShopCatalog({String? token}) async {
    final response = await _api.getShopCosmetics(token: token);
    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    return null;
  }

  /// Stubbed single entry point for cosmetic item purchase.
  /// Calls POST /shop/purchase with { 'item_id': itemId, 'item_type': itemType }.
  Future<ShopPurchaseResponse?> purchase({
    required dynamic itemId,
    required String itemType,
    required String token,
  }) async {
    final response = await _api.purchaseCosmeticsItem(
      itemId: itemId,
      itemType: itemType,
      token: token,
    );
    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    return null;
  }
}
