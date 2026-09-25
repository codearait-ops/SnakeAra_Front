import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Service managing Firebase Authentication operations.
class FirebaseAuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isAuthenticated => _auth.currentUser != null;

  String? get currentUid => _auth.currentUser?.uid;

  /// Register a new user with Email and Password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuthService] Register error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAuthService] Unexpected register error: $e');
      rethrow;
    }
  }

  /// Sign in an existing user with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuthService] SignIn error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAuthService] Unexpected sign in error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuthService] Reset password error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAuthService] Unexpected reset password error: $e');
      rethrow;
    }
  }

  /// Get ID token for API calls / authorization
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('[FirebaseAuthService] Error fetching ID token: $e');
      return null;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[FirebaseAuthService] Sign out error: $e');
      rethrow;
    }
  }
}
