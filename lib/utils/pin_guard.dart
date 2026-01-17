import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../screens/verify_pin_screen.dart';

/// Utility class for PIN protection.
/// 
/// Provides helper methods to check PIN and show verification screen
/// before allowing access to protected features.
class PinGuard {
  static final PinService _pinService = PinService();

  /// Check if PIN is required and verify it before proceeding.
  /// 
  /// [context] - BuildContext for navigation
  /// [onVerified] - Callback to execute after successful PIN verification
  /// [title] - Optional title for verification screen
  /// [subtitle] - Optional subtitle for verification screen
  /// 
  /// Returns true if PIN verified or not required, false if verification failed
  static Future<bool> requirePin(
    BuildContext context, {
    VoidCallback? onVerified,
    String? title,
    String? subtitle,
  }) async {
    // Check if PIN exists
    final pinExists = await _pinService.pinExists();
    
    if (!pinExists) {
      // No PIN set - allow access
      if (onVerified != null) {
        onVerified();
      }
      return true;
    }

    // PIN exists - show verification screen
    if (!context.mounted) return false;
    
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyPinScreen(
          onVerified: onVerified,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );

    return verified == true;
  }
}
