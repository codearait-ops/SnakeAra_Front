import 'package:get/get.dart';
import '../../../services/league_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/league_models.dart';

class MyLeagueHistoryController extends GetxController {
  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;
  RxList<LeagueHistoryEntry> history = <LeagueHistoryEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final authController = Get.find<AuthController>();
      final token = authController.currentUser.value?.token;
      if (token == null || token.isEmpty) {
        isLoading.value = false;
        history.clear();
        return;
      }
      final leagueApi = Get.find<LeagueApiService>();
      final res = await leagueApi.getMyLeagueHistory(token);
      if (res.isSuccess && res.data != null) {
        history.assignAll(res.data!);
      } else {
        history.clear();
      }
    } catch (e) {
      history.clear();
    } finally {
      isLoading.value = false;
    }
  }
}

