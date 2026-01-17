import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'caregiver_profile_service.dart';
import 'pin_service.dart';

/// Service for checking caregiver setup completion.
/// 
/// Checks if:
/// - Caregiver account exists (Firebase Auth)
/// - Caregiver profile exists (Firestore)
/// - PIN is created
/// 
/// Persists setup completion status locally.
class SetupService {
  static const String _setupCompleteKey = 'caregiver_setup_complete';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CaregiverProfileService _profileService = CaregiverProfileService();
  final PinService _pinService = PinService();

  /// Check if caregiver setup is complete.
  /// 
  /// Returns true if:
  /// - User is authenticated
  /// - Profile exists in Firestore
  /// - PIN is created
  Future<bool> isSetupComplete() async {
    // Check local cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedComplete = prefs.getBool(_setupCompleteKey);
    
    // If cached as complete, verify it's still true
    if (cachedComplete == true) {
      final stillComplete = await _verifySetupComplete();
      if (stillComplete) {
        return true;
      } else {
        // Setup was undone (e.g., account deleted), clear cache
        await prefs.remove(_setupCompleteKey);
      }
    }

    // Check setup status
    final isComplete = await _verifySetupComplete();
    
    // Cache the result
    if (isComplete) {
      await prefs.setBool(_setupCompleteKey, true);
    }
    
    return isComplete;
  }

  /// Verify setup completion by checking all requirements.
  Future<bool> _verifySetupComplete() async {
    // Check if user is authenticated
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    // Check if profile exists
    final profileExists = await _profileService.profileExists();
    if (!profileExists) {
      return false;
    }

    // Check if PIN exists
    final pinExists = await _pinService.pinExists();
    if (!pinExists) {
      return false;
    }

    return true;
  }

  /// Mark setup as complete (called after PIN creation).
  Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompleteKey, true);
  }

  /// Clear setup completion status (for testing/reset).
  Future<void> clearSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_setupCompleteKey);
  }

  /// Check if user is authenticated (but setup may not be complete).
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }
}
