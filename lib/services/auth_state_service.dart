import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pin_service.dart';

/// Service for tracking authentication state and first login status.
/// 
/// Tracks whether a user has logged in at least once with email/password.
/// After first login, subsequent app opens will use PIN authentication.
class AuthStateService {
  static const String _hasLoggedInKey = 'has_logged_in_once';
  static const String _lastUserIdKey = 'last_user_id';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user has logged in at least once.
  /// 
  /// Returns true if user has previously logged in with email/password.
  Future<bool> hasLoggedInOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user matches the last logged in user.
  /// 
  /// Returns true if the current Firebase user matches the stored user ID.
  /// This ensures PIN authentication is only used for the same user.
  Future<bool> isSameUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastUserId = prefs.getString(_lastUserIdKey);
      
      return lastUserId == currentUser.uid;
    } catch (e) {
      return false;
    }
  }

  /// Mark that user has logged in (called after successful email/password login).
  /// 
  /// Stores the user ID to verify same user on subsequent opens.
  Future<void> markLoggedIn() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('AuthStateService: Cannot mark logged in - no current user');
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasLoggedInKey, true);
      await prefs.setString(_lastUserIdKey, currentUser.uid);
      
      if (kDebugMode) {
        debugPrint('AuthStateService: Marked user ${currentUser.uid} as logged in');
      }
    } catch (e) {
      debugPrint('Failed to mark logged in: $e');
    }
  }

  /// Clear login status (for logout or account switch).
  Future<void> clearLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasLoggedInKey);
      await prefs.remove(_lastUserIdKey);
    } catch (e) {
      debugPrint('Failed to clear login status: $e');
    }
  }

  /// Check if PIN authentication should be used.
  /// 
  /// Returns true if:
  /// - User has logged in at least once
  /// - Current user matches the last logged in user
  /// - User is currently authenticated
  /// - A PIN exists for the user
  Future<bool> shouldUsePinAuth() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint('AuthStateService: No current user');
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint('AuthStateService: Current user ID = ${currentUser.uid}');
    }

    final hasLoggedIn = await hasLoggedInOnce();
    if (kDebugMode) {
      debugPrint('AuthStateService: hasLoggedInOnce = $hasLoggedIn');
    }
    if (!hasLoggedIn) {
      if (kDebugMode) {
        debugPrint('AuthStateService: User has not logged in once yet');
      }
      return false;
    }

    final isSame = await isSameUser();
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      final lastUserId = prefs.getString(_lastUserIdKey);
      debugPrint('AuthStateService: isSameUser = $isSame (current: ${currentUser.uid}, last: $lastUserId)');
    }
    if (!isSame) {
      if (kDebugMode) {
        debugPrint('AuthStateService: User changed');
      }
      return false;
    }

    // Check if PIN exists
    final pinService = PinService();
    final pinExists = await pinService.pinExists();
    
    if (kDebugMode) {
      debugPrint('AuthStateService: PIN exists = $pinExists');
    }
    
    return pinExists;
  }
}
