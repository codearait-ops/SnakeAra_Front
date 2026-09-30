import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/bindings/initial_binding.dart';
import 'app/core/init/app_initializer.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/translations/app_translations.dart';
import 'app/routes/app_routes.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/wallet/controllers/wallet_controller.dart';
import 'features/wallet/widgets/coin_fly_animation_overlay.dart';

/// Entry point for the Snake game.
Future<void> main() async {
  // Capture uncaught Flutter framework/widget tree errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 [FlutterError] ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint('📍 [FlutterStack] ${details.stack}');
    }
  };

  // Capture uncaught asynchronous errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('💥 [UncaughtPlatformError] $error');
    debugPrint('📍 [PlatformStack] $stack');
    return true;
  };

  await AppInitializer.init();
  runApp(const SnakeApp());
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return GetMaterialApp(
      title: 'SnakeAra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      translations: AppTranslations(),
      locale: settings.currentLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fadeIn,
      routingCallback: (routing) {
        debugPrint(
          '🧭 [SnakeApp] routingCallback: current=${routing?.current}, isBack=${routing?.isBack}',
        );
        if (routing != null &&
            (routing.current == AppRoutes.menu ||
                routing.current == '/' ||
                routing.current == '/home' ||
                (routing.current.contains('menu')))) {
          if (Get.isRegistered<WalletController>()) {
            Get.find<WalletController>().checkAndTriggerPendingCoins();
          }
        }
      },
      builder: (context, child) {
        return Stack(
          children: [if (child != null) child, const CoinFlyAnimationOverlay()],
        );
      },
    );
  }
}
