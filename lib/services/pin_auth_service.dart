import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pin_service.dart';

/// Simple service for managing PIN authentication on app reopen.
/// 
/// Checks if PIN should be required when app is reopened.
class PinAuthService {
  static const String _pinVerifiedKey = 'pin_verified_this_session';
  static const String _lastVerifiedUserIdKey = 'last_verified_user_id';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PinService _pinService = PinService();

  /// Check if PIN verification is required for the current user.
  /// 
  /// Returns true if:
  /// - User is logged in
  /// - PIN exists for the user
  /// - PIN hasn't been verified this session
  Future<bool> isPinRequired() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    // Check if PIN exists
    final pinExists = await _pinService.pinExists();
    if (!pinExists) {
      return false;
    }

    // Check if PIN was already verified this session
    final prefs = await SharedPreferences.getInstance();
    final verifiedUserId = prefs.getString(_lastVerifiedUserIdKey);
    final isVerified = prefs.getBool(_pinVerifiedKey) ?? false;
    
    // PIN is required if it exists and hasn't been verified for this user this session
    final requiresPin = verifiedUserId != currentUser.uid || !isVerified;
    
    if (kDebugMode) {
      debugPrint('PinAuthService: isPinRequired = $requiresPin');
      debugPrint('PinAuthService: pinExists = $pinExists');
      debugPrint('PinAuthService: verifiedUserId = $verifiedUserId, currentUserId = ${currentUser.uid}');
      debugPrint('PinAuthService: isVerified = $isVerified');
    }
    
    return requiresPin;
  }

  /// Mark PIN as verified for this session.
  /// 
  /// This prevents asking for PIN again until app is closed and reopened.
  Future<void> markPinVerified() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pinVerifiedKey, true);
      await prefs.setString(_lastVerifiedUserIdKey, currentUser.uid);
      
      if (kDebugMode) {
        debugPrint('PinAuthService: Marked PIN as verified for user ${currentUser.uid}');
      }
    } catch (e) {
      debugPrint('PinAuthService: Failed to mark PIN verified: $e');
    }
  }

  /// Clear PIN verification status.
  /// 
  /// Call this when app is reopened to force PIN check again.
  Future<void> clearPinVerification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinVerifiedKey);
      await prefs.remove(_lastVerifiedUserIdKey);
      
      if (kDebugMode) {
        debugPrint('PinAuthService: Cleared PIN verification status');
      }
    } catch (e) {
      debugPrint('PinAuthService: Failed to clear PIN verification: $e');
    }
  }
}
