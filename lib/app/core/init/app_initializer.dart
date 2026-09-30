import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../firebase_options.dart';
import '../../../services/notification_service.dart';
import '../../../services/sound_service.dart';
import '../../../services/storage_service.dart';
import '../bindings/initial_binding.dart';
import '../widgets/custom_error_widget.dart';

/// Handles application initialization before [runApp] is executed.
abstract class AppInitializer {
  /// Initializes essential system settings, Firebase, and core services.
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🚀 [AppInitializer] Starting SnakeAra app initialization...');

    // 1. Error Handler
    CustomErrorWidget.initialize();
    debugPrint('🛡️ [AppInitializer] CustomErrorWidget initialized');

    // 2. Firebase Initialization
    await _initFirebase();

    // 3. System UI & Orientation
    await _initSystemUI();
    debugPrint('📱 [AppInitializer] System UI and orientation configured');

    // 4. Core Async Services
    debugPrint(
      '⚙️ [AppInitializer] Initializing core async services (Storage, Sound, Notifications)...',
    );
    await _initAsyncServices();
    debugPrint('✅ [AppInitializer] Core async services initialized');

    // 5. Initial Dependency Injection
    debugPrint(
      '💉 [AppInitializer] Registering initial bindings and controllers...',
    );
    InitialBinding().dependencies();
    debugPrint('🎉 [AppInitializer] Application initialization complete!');
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('[Firebase] ⏱️ Firebase.initializeApp timed out (offline mode).');
          return Firebase.app();
        },
      );
      debugPrint('[Firebase] Initialized successfully');
    } catch (e) {
      debugPrint('[Firebase] Initialization error: $e');
    }
  }

  static Future<void> _initSystemUI() async {
    // Lock orientation to portrait
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Set immersive fullscreen mode
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static Future<void> _initAsyncServices() async {
    await Get.putAsync<StorageService>(
      () => StorageService().init(),
      permanent: true,
    );
    await Get.putAsync<SoundService>(
      () => SoundService().init(),
      permanent: true,
    );
    try {
      await Get.putAsync<NotificationService>(
        () => NotificationService().init(),
        permanent: true,
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint(
            '⚠️ [AppInitializer] NotificationService init timed out, proceeding.',
          );
          if (!Get.isRegistered<NotificationService>()) {
            Get.put<NotificationService>(NotificationService(), permanent: true);
          }
          return Get.find<NotificationService>();
        },
      );
    } catch (e) {
      debugPrint('⚠️ [AppInitializer] NotificationService init error: $e');
      if (!Get.isRegistered<NotificationService>()) {
        Get.put<NotificationService>(NotificationService(), permanent: true);
      }
    }
  }
}
