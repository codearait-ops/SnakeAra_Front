import 'package:get/get.dart';
import '../controllers/league_controller.dart';

/// Binds [LeagueController] to the GetX dependency graph lazily.
/// When the user navigates away from the league route, GetX automatically
/// calls [LeagueController.onClose], stopping background polling timers.
class LeagueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeagueController>(() => LeagueController());
  }
}
