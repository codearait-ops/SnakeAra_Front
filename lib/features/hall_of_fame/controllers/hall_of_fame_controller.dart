import 'package:get/get.dart';
import '../models/hall_of_fame_models.dart';
import '../../../services/league_api_service.dart';

class HallOfFameController extends GetxController {
  final LeagueApiService _api = Get.find<LeagueApiService>();

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxList<HallOfFameEntry> seasons = <HallOfFameEntry>[].obs;
  final Rx<HallOfFameBundleResponse?> bundle = Rx<HallOfFameBundleResponse?>(null);
  final RxString currentTier = ''.obs;

  // In-memory cache by tier to prevent redundant network requests on chip taps
  final Map<String, HallOfFameBundleResponse> _bundleCache = {};

  @override
  void onInit() {
    super.onInit();
    fetchHallOfFameBundle();
  }

  /// Fetches Hall of Fame bundle (GET /hall-of-fame/bundle) with optional tier query parameter.
  Future<void> fetchHallOfFameBundle({String? tier, bool forceRefresh = false}) async {
    final targetTier = tier ?? '';

    // If already cached in memory and not force refreshing, load instantly without network call
    if (!forceRefresh && _bundleCache.containsKey(targetTier)) {
      final cached = _bundleCache[targetTier]!;
      bundle.value = cached;
      seasons.assignAll(cached.allSeasons);
      currentTier.value = targetTier;
      isLoading.value = false;
      errorMessage.value = '';
      return;
    }

    if (isLoading.value && seasons.isNotEmpty) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    currentTier.value = targetTier;

    try {
      final res = await _api.getHallOfFameBundle(tier: tier);
      if (res.isSuccess && res.data != null) {
        _bundleCache[targetTier] = res.data!;
        bundle.value = res.data!;
        seasons.assignAll(res.data!.allSeasons);
      } else {
        errorMessage.value = res.message ?? 'Failed to load Hall of Fame';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Backward compatible wrapper
  Future<void> fetchHallOfFame({bool forceRefresh = false}) async {
    await fetchHallOfFameBundle(
      tier: currentTier.value.isNotEmpty ? currentTier.value : null,
      forceRefresh: forceRefresh,
    );
  }

  // Method to fetch details for a specific season (can be called from SeasonDetailView)
  Future<SeasonDetail?> fetchSeasonDetail(int seasonNumber) async {
    try {
      final res = await _api.getSeasonDetail(seasonNumber);
      if (res.isSuccess && res.data != null) {
        return res.data;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }
}
