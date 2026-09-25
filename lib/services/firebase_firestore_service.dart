import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../features/auth/models/user_model.dart';

/// Service managing Firestore database operations for users, high scores, and game stats.
class FirebaseFirestoreService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _scoresRef =>
      _db.collection('scores');

  /// Create or update user profile document in Firestore
  Future<void> saveUserProfile(UserModel user) async {
    try {
      final docRef = _usersRef.doc(user.id);
      final data = {
        'id': user.id,
        'username': user.username,
        'avatarId': user.avatarId,
        'avatarUrl': user.avatarUrl,
        'email': user.email,
        'bio': user.bio,
        'authProvider': user.authProvider,
        'classicHighscore': user.classicHighscore,
        'xpTotal': user.xpTotal,
        'level': user.level,
        'nextLevelXp': user.nextLevelXp,
        'honor': user.honor,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
      debugPrint('[FirebaseFirestoreService] User profile saved: ${user.id}');
    } catch (e) {
      debugPrint('[FirebaseFirestoreService] Error saving user profile: $e');
      rethrow;
    }
  }

  /// Fetch user profile from Firestore by user ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint('[FirebaseFirestoreService] Error getting user profile: $e');
      return null;
    }
  }

  /// Real-time stream of user profile changes
  Stream<UserModel?> streamUserProfile(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }

  /// Update player score in Firestore
  Future<void> submitScore({
    required String userId,
    required String username,
    required String avatarId,
    required int score,
    required String gameMode,
  }) async {
    try {
      // 1. Add score record
      await _scoresRef.add({
        'userId': userId,
        'username': username,
        'avatarId': avatarId,
        'score': score,
        'gameMode': gameMode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update user's classicHighscore if higher
      final userDoc = await _usersRef.doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final currentHigh = userDoc.data()!['classicHighscore'] as int? ?? 0;
        if (score > currentHigh) {
          await _usersRef.doc(userId).update({
            'classicHighscore': score,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('[FirebaseFirestoreService] Error submitting score: $e');
    }
  }

  /// Fetch top high scores for leaderboard
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _usersRef
          .orderBy('classicHighscore', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('[FirebaseFirestoreService] Error fetching leaderboard: $e');
      return [];
    }
  }
}
