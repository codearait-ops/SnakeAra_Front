import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

/// Binding to initialize SplashController when entering the splash route.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController());
  }
}
