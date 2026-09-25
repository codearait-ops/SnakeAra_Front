import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api_service.dart';
import 'league_api_service.dart';
import 'firebase_firestore_service.dart';
import 'storage_service.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../app/core/utils/hmac_utils.dart';

class GameEventLogger extends GetxService {
  String? _sessionId;
  String? get sessionId => _sessionId;
  
  DateTime? _localStartTime;
  final List<Map<String, dynamic>> _events = [];
  Timer? _heartbeatTimer;
  String? _currentGameMode;

  ApiService get _api => Get.find<ApiService>();
  LeagueApiService get _leagueApi => Get.find<LeagueApiService>();
  AuthController get _auth => Get.find<AuthController>();
  StorageService get _storage => Get.find<StorageService>();

  // Use this stream to notify UI about session expiration
  final RxBool sessionExpired = false.obs;

  // Track pending offline score submission status for retry UI
  final RxBool hasPendingSubmission = false.obs;
  final RxBool isRetryingSubmission = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<StorageService>()) {
      hasPendingSubmission.value = _storage.hasPendingScoreSubmission();
    }
  }

  /// Starts a session and initializes the heartbeat. Returns false if network fails.
  Future<bool> startSession(
    String gameMode, {
    int? dailyChallengeId,
    bool? isAdRetry,
  }) async {
    _heartbeatTimer?.cancel();
    sessionExpired.value = false;
    _events.clear();
    if (Get.isRegistered<StorageService>()) {
      await _storage.clearPendingScoreSubmission();
      hasPendingSubmission.value = false;
    }

    final user = _auth.currentUser.value;
    if (user == null) {
      debugPrint('[EventLogger] Cannot start session: User not logged in.');
      return false;
    }

    final response = await _api.startGameSession(
      gameMode, 
      user.token,
      dailyChallengeId: dailyChallengeId,
      isAdRetry: isAdRetry,
    );
    
    if (response.isSuccess && response.sessionId != null) {
      _sessionId = response.sessionId;
      _currentGameMode = gameMode;
      _localStartTime = DateTime.now();

      // Start 4-minute heartbeat timer
      _heartbeatTimer = Timer.periodic(const Duration(minutes: 4), (_) {
        _sendHeartbeat();
      });

      debugPrint('[EventLogger] Started session $_sessionId for $gameMode');
      return true;
    } else {
      debugPrint('[EventLogger] Failed to start session: ${response.error}');
      return false;
    }
  }

  Future<void> _sendHeartbeat() async {
    if (_sessionId == null) return;

    final user = _auth.currentUser.value;
    if (user == null) return;

    final response = await _api.sendHeartbeat(_sessionId!, user.token);
    
    if (response.isSessionExpired) {
      _heartbeatTimer?.cancel();
      sessionExpired.value = true;
      debugPrint('[EventLogger] Heartbeat returned session expired (404/410/401)');
    } else if (response.isNetworkError) {
      debugPrint('[EventLogger] Heartbeat network error (ignored) - ${response.message}');
    } else {
      debugPrint('[EventLogger] Heartbeat successful');
    }
  }

  static const Set<String> _validGameOverReasons = {
    'wall_collision',
    'self_collision',
    'infection_reached_head',
    'laser_head_hit',
    'timer_expired',
    'crab_collision',
    'unknown',
  };

  /// Normalizes any arbitrary reason to one of the 7 backend-approved strings.
  static String sanitizeGameOverReason(dynamic reason) {
    if (reason == null) return 'unknown';
    final str = reason.toString().trim();
    if (_validGameOverReasons.contains(str)) {
      return str;
    }
    // Mapping common alternative reason aliases
    switch (str) {
      case 'laser_collision':
      case 'hit_laser':
        return 'laser_head_hit';
      case 'crab_hit':
      case 'crab_head_hit':
      case 'hit_crab':
        return 'crab_collision';
      case 'time_out':
      case 'timeout':
      case 'time_expired':
        return 'timer_expired';
      case 'obstacle_collision':
      case 'bomb_collision':
      case 'hit_wall':
      case 'hit_obstacle':
        return 'wall_collision';
      case 'bit_yourself':
        return 'self_collision';
      case 'parasite_consumed':
        return 'infection_reached_head';
      default:
        return 'unknown';
    }
  }

  /// Logs an event with a precise time offset
  void logEvent(String type, Map<String, dynamic> data) {
    if (_localStartTime == null) return;
    
    final int t = DateTime.now().difference(_localStartTime!).inMilliseconds;
    final sanitizedData = Map<String, dynamic>.from(data);

    if (type == 'game_over') {
      sanitizedData['reason'] = sanitizeGameOverReason(sanitizedData['reason']);
    }

    _events.add({
      'type': type,
      't': t,
      'data': sanitizedData,
    });
    
    debugPrint('[EventLogger] Logged $type at t=$t with data: $sanitizedData');
  }

  /// Submits the final score and all accumulated events.
  /// When [isLeague] is true, routes dedicatedly to POST /api/league/score/submit.
  Future<SubmitScoreResponse> submitFinalScore(int localValue, {bool isLeague = false}) async {
    _heartbeatTimer?.cancel();

    if (_sessionId == null || _currentGameMode == null) {
      return SubmitScoreResponse(isNetworkError: true, message: 'No active session');
    }

    final user = _auth.currentUser.value;
    if (user == null) {
      return SubmitScoreResponse(isSessionExpired: true, message: 'User not logged in');
    }

    // Record score to Firestore in background
    if (Get.isRegistered<FirebaseFirestoreService>()) {
      Get.find<FirebaseFirestoreService>().submitScore(
        userId: user.id,
        username: user.username,
        avatarId: user.avatarId,
        score: localValue,
        gameMode: _currentGameMode!,
      );
    }

    // Prepare events payload: ensure valid game_over event exists and has valid reason
    final preparedEvents = <Map<String, dynamic>>[];
    bool hasGameOver = false;

    for (final ev in _events) {
      final evMap = Map<String, dynamic>.from(ev);
      if (evMap['type'] == 'game_over') {
        hasGameOver = true;
        final data = Map<String, dynamic>.from(evMap['data'] ?? {});
        data['reason'] = sanitizeGameOverReason(data['reason']);
        evMap['data'] = data;
      }
      preparedEvents.add(evMap);
    }

    if (!hasGameOver) {
      final int t = _localStartTime != null
          ? DateTime.now().difference(_localStartTime!).inMilliseconds
          : 0;
      preparedEvents.add({
        'type': 'game_over',
        't': t,
        'data': {
          'reason': 'unknown',
          'final_score': localValue,
        },
      });
    }

    final hmacSignature = HmacUtils.generateScoreSignature(
      gameMode: _currentGameMode!,
      value: localValue,
      userId: user.id,
    );

    final pendingPayload = <String, dynamic>{
      'sessionId': _sessionId!,
      'gameMode': _currentGameMode!,
      'value': localValue,
      'events': preparedEvents,
      'token': user.token,
      'userId': user.id,
      'hmacSignature': hmacSignature,
      'isLeague': isLeague,
    };

    // Submit all events collected so far to the dedicated endpoint
    final response = isLeague
        ? await _leagueApi.submitLeagueScore(
            sessionId: _sessionId!,
            gameMode: _currentGameMode!,
            value: localValue,
            events: preparedEvents,
            token: user.token,
            userId: user.id,
            hmacSignature: hmacSignature,
          )
        : await _api.submitScore(
            sessionId: _sessionId!,
            gameMode: _currentGameMode!,
            value: localValue,
            events: preparedEvents,
            token: user.token,
            userId: user.id,
            hmacSignature: hmacSignature,
          );

    if (response.isSuccess) {
      _events.clear(); // Only clear on success
      if (Get.isRegistered<StorageService>()) {
        await _storage.clearPendingScoreSubmission();
        hasPendingSubmission.value = false;
      }
      debugPrint('[EventLogger] Final score submitted successfully (isLeague: $isLeague)');
    } else if (response.isRejected) {
      // 422: Rejected. Leave events intact for local debug but don't retry.
      if (Get.isRegistered<StorageService>()) {
        await _storage.clearPendingScoreSubmission();
        hasPendingSubmission.value = false;
      }
      debugPrint('[EventLogger] Final score REJECTED (422) - ${response.message}');
    } else if (response.isSessionExpired) {
      if (Get.isRegistered<StorageService>()) {
        await _storage.clearPendingScoreSubmission();
        hasPendingSubmission.value = false;
      }
      debugPrint('[EventLogger] Final score failed: Session Expired');
    } else if (response.isNetworkError) {
      // Network error: persist payload locally so user can retry with exact same payload & HMAC signature
      debugPrint('[EventLogger] Final score failed: Network Error - ${response.message}');
      if (Get.isRegistered<StorageService>()) {
        await _storage.savePendingScoreSubmission(pendingPayload);
        hasPendingSubmission.value = true;
      }
    }

    return response;
  }

  /// Retries a previously failed score submission using the exact stored payload & HMAC signature.
  Future<SubmitScoreResponse?> retryPendingScore() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final payload = _storage.getPendingScoreSubmission();
    if (payload == null) {
      hasPendingSubmission.value = false;
      return null;
    }

    final user = _auth.currentUser.value;
    final storedUserId = payload['userId']?.toString();

    // Defensively verify identity match:
    // If the user has logged out or a different user is now authenticated on this device,
    // do not attempt submission, silently clear the stale pending payload, and return null.
    if (user == null ||
        user.token.isEmpty ||
        storedUserId == null ||
        user.id.toString() != storedUserId) {
      debugPrint(
        '[EventLogger] Stale pending score discarded: user identity mismatch or not authenticated '
        '(currentUser: ${user?.id}, storedUser: $storedUserId)',
      );
      await _storage.clearPendingScoreSubmission();
      hasPendingSubmission.value = false;
      return null;
    }

    final token = user.token;
    final userId = user.id;

    isRetryingSubmission.value = true;
    try {
      final isLeague = payload['isLeague'] == true;
      final events = (payload['events'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          <Map<String, dynamic>>[];
      final sessionId = payload['sessionId'] as String;
      final gameMode = payload['gameMode'] as String;
      final value = payload['value'] as int;
      final hmacSignature = payload['hmacSignature'] as String;

      final response = isLeague
          ? await _leagueApi.submitLeagueScore(
              sessionId: sessionId,
              gameMode: gameMode,
              value: value,
              events: events,
              token: token,
              userId: userId,
              hmacSignature: hmacSignature,
            )
          : await _api.submitScore(
              sessionId: sessionId,
              gameMode: gameMode,
              value: value,
              events: events,
              token: token,
              userId: userId,
              hmacSignature: hmacSignature,
            );

      if (response.isSuccess) {
        await _storage.clearPendingScoreSubmission();
        hasPendingSubmission.value = false;
        _events.clear();
        debugPrint('[EventLogger] Offline score retry succeeded for session $sessionId');
      } else if (response.isRejected || response.isSessionExpired) {
        await _storage.clearPendingScoreSubmission();
        hasPendingSubmission.value = false;
        debugPrint('[EventLogger] Offline score retry rejected/expired: ${response.message}');
      } else if (response.isNetworkError) {
        debugPrint('[EventLogger] Offline score retry failed again with network error');
      }

      return response;
    } finally {
      isRetryingSubmission.value = false;
    }
  }
}
