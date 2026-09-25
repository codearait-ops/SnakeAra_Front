import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../../firebase_options.dart';
import '../app/core/constants/app_constants.dart';
import '../app/routes/app_routes.dart';
import '../features/auth/controllers/auth_controller.dart';
import 'api_service.dart';

/// Top-level background message handler required by FirebaseMessaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('================= 🔔 [FCM BACKGROUND MESSAGE] =================');
  debugPrint('🆔 Message ID: ${message.messageId}');
  debugPrint('📡 From: ${message.from}');
  debugPrint('📦 Data: ${message.data}');
  debugPrint('📝 Notification Title: ${message.notification?.title}');
  debugPrint('📝 Notification Body: ${message.notification?.body}');
  debugPrint('🕒 Sent Time: ${message.sentTime}');
  debugPrint('=================================================================');
}

/// Service managing push notifications, topic subscriptions, and local notifications.
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String dailyChallengesTopic = 'daily_challenges';
  static const String channelId = 'daily_challenge_notifications';
  static const String channelName = 'Daily Challenge Notifications';
  static const String channelDescription =
      'Notifications for new daily challenges and game events';

  late final AndroidNotificationChannel _androidChannel;

  /// Initializes notification services, channels, listeners, and topic subscriptions.
  Future<NotificationService> init() async {
    try {
      debugPrint('[NotificationService] 🚀 Initializing NotificationService...');

      // 1. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request user permissions (Android 13+ & iOS)
      await _requestPermissions();

      // 3. Enable foreground notification presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Setup Android notification channel
      await _setupLocalNotifications();

      // 5. Listen for foreground and background click events
      _setupMessageHandlers();

      // 6. Subscribe to daily challenges and missions topics by default
      await subscribeToTopic(dailyChallengesTopic);
      await subscribeToTopic('daily_missions');

      // 7. Send FCM Device Token to backend
      await sendDeviceTokenToServer();

      // 8. Listen for token refresh and sync with server
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('[NotificationService] 🔄 FCM Token refreshed: $newToken');
        sendDeviceTokenToServer();
      });
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] ❌ Initialization error: $e');
      debugPrint('[NotificationService] StackTrace: $stackTrace');
    }

    return this;
  }

  /// Sends device token to backend (POST /api/device-token)
  Future<void> sendDeviceTokenToServer({String? authToken}) async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[NotificationService] ⚠️ No FCM device token available.');
        return;
      }

      debugPrint('[NotificationService] 🔑 FCM Token: $token');

      Dio dio;
      if (Get.isRegistered<ApiService>()) {
        dio = Get.find<ApiService>().dio;
      } else {
        dio = Dio(BaseOptions(baseUrl: kBaseUrl));
      }

      final effectiveAuth = authToken ??
          (Get.isRegistered<AuthController>()
              ? Get.find<AuthController>().currentUser.value?.token
              : null);

      final headers = <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (effectiveAuth != null && effectiveAuth.isNotEmpty) {
        headers['Authorization'] = 'Bearer $effectiveAuth';
      }

      final platformName = Platform.isAndroid
          ? 'android'
          : (Platform.isIOS ? 'ios' : 'unknown');

      debugPrint(
        '🌐 [NotificationService] POST /device-token (platform: $platformName, auth: ${effectiveAuth != null ? "yes" : "no"})',
      );

      final response = await dio.post(
        '/device-token',
        data: {
          'token': token,
          'platform': platformName,
          'app_version': '1.0.0',
        },
        options: Options(headers: headers),
      );

      debugPrint(
        '🌐 [NotificationService] POST /device-token => ${response.statusCode} | ${response.data}',
      );
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error sending device token to server: $e');
    }
  }

  /// Request permissions for iOS and Android 13+
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      '[NotificationService] 🛡️ User notification permission status: ${settings.authorizationStatus}',
    );
  }

  /// Setup local notifications for Android foreground display
  Future<void> _setupLocalNotifications() async {
    _androidChannel = const AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[NotificationService] 👆 Local Notification Tapped: Payload=${response.payload}');
        _handlePayload(response.payload);
      },
    );
  }

  /// Configure handlers for incoming messages and notification taps
  void _setupMessageHandlers() {
    // 1. Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('================= 🔔 [FCM FOREGROUND MESSAGE] =================');
      debugPrint('🆔 Message ID: ${message.messageId}');
      debugPrint('📡 From: ${message.from}');
      debugPrint('📦 Data: ${message.data}');
      debugPrint('📝 Notification Title: ${message.notification?.title}');
      debugPrint('📝 Notification Body: ${message.notification?.body}');
      debugPrint('🕒 Sent Time: ${message.sentTime}');
      debugPrint('================================================================');
      _showForegroundNotification(message);
    });

    // 2. Notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('================= 👆 [FCM MESSAGE OPENED APP] =================');
      debugPrint('🆔 Message ID: ${message.messageId}');
      debugPrint('📡 From: ${message.from}');
      debugPrint('📦 Data: ${message.data}');
      debugPrint('📝 Title: ${message.notification?.title}');
      debugPrint('================================================================');
      _handleMessageNavigation(message);
    });

    // 3. Notification tap when app was terminated
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('================= 🚀 [FCM TERMINATED INITIAL MESSAGE] =================');
        debugPrint('🆔 Message ID: ${message.messageId}');
        debugPrint('📡 From: ${message.from}');
        debugPrint('📦 Data: ${message.data}');
        debugPrint('📝 Title: ${message.notification?.title}');
        debugPrint('========================================================================');
        _handleMessageNavigation(message);
      }
    });
  }

  /// Show heads-up notification when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = message.notification?.android;
      final type = message.data['type']?.toString();

      // Extract title and body from notification payload or fallback to data payload
      String? title = notification?.title ?? message.data['title'] ?? message.data['header'];
      String? body = notification?.body ?? message.data['body'] ?? message.data['message'];

      // Construct fallback copy per Weekend League Addendum §10 if payload lacks text
      if (title == null || body == null) {
        if (type == 'league_started') {
          title ??= 'لیگ هفتگی آغاز شد! 🏆';
          body ??= 'رقابت‌های گروه شما آغاز شد. برای ثبت امتیاز کلیک کنید!';
        } else if (type == 'league_registration_reminder') {
          final isFree = message.data['is_free_entry'] == true ||
              message.data['is_free_entry']?.toString() == 'true';
          title ??= 'یادآوری ثبت‌نام لیگ ⏰';
          body ??= isFree
              ? 'اولین لیگ شما کاملاً رایگان است! مهلت ثبت‌نام رو به پایان است.'
              : 'مهلت ثبت‌نام لیگ هفتگی به‌زودی بسته می‌شود. هم‌اکنون ثبت‌نام کنید!';
        } else if (type == 'league_cancelled_low_turnout') {
          final coins = int.tryParse(message.data['coins_refunded']?.toString() ?? '0') ?? 0;
          title ??= 'لغو مسابقات لیگ این هفته';
          body ??= coins > 0
              ? 'لیگ این هفته به دلیل به حد نصاب نرسیدن لغو شد و $coins سکه بازگردانده شد.'
              : 'لیگ این هفته به دلیل به حد نصاب نرسیدن شرکت‌کنندگان لغو شد.';
        }
      }

      String? targetRoute = message.data['route']?.toString();
      if (targetRoute == null || targetRoute.isEmpty) {
        if (type == 'league_started' ||
            type == 'league_registration_reminder' ||
            type == 'league_cancelled_low_turnout') {
          targetRoute = AppRoutes.league;
        } else if (message.from?.contains(dailyChallengesTopic) == true) {
          targetRoute = AppRoutes.dailyMission;
        }
      }

      if (title != null || body != null) {
        debugPrint('[NotificationService] 📢 Showing local notification: "$title" - "$body" (route: $targetRoute)');
        await _localNotifications.show(
          notification.hashCode != 0 ? notification.hashCode : message.messageId.hashCode,
          title ?? 'SnakeAra',
          body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android?.smallIcon ?? '@mipmap/launcher_icon',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: targetRoute,
        );
      } else {
        debugPrint('[NotificationService] ℹ️ Message has no title or body to display as notification');
      }
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] ❌ Error showing foreground notification: $e');
      debugPrint('[NotificationService] StackTrace: $stackTrace');
    }
  }

  /// Handle navigation based on message data or topic
  void _handleMessageNavigation(RemoteMessage message) {
    final route = message.data['route'];
    final topic = message.from;
    final type = message.data['type']?.toString();

    debugPrint('[NotificationService] 🧭 Handling navigation. Route: $route, Topic: $topic, Type: $type');

    // Weekend League deep-link handling (Addendum §10)
    if (type == 'league_started' ||
        type == 'league_registration_reminder' ||
        type == 'league_cancelled_low_turnout') {
      Get.toNamed(AppRoutes.league);
      return;
    }

    if (route != null && route.toString().isNotEmpty) {
      Get.toNamed(route.toString());
    } else if (topic != null && topic.contains(dailyChallengesTopic)) {
      Get.toNamed(AppRoutes.dailyMission);
    }
  }

  /// Handle navigation from local notification click payload
  void _handlePayload(String? payload) {
    debugPrint('[NotificationService] 🧭 Handling payload navigation: $payload');
    if (payload != null && payload.isNotEmpty) {
      Get.toNamed(payload);
    }
  }

  /// Subscribes to an FCM topic (e.g. daily_challenges)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('[NotificationService] ✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Failed to subscribe to topic "$topic": $e');
    }
  }

  /// Unsubscribes from an FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[NotificationService] 🔕 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Failed to unsubscribe from topic "$topic": $e');
    }
  }
}
