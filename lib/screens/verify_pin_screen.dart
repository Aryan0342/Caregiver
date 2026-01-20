import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/pin_service.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import 'pin_entry_screen.dart';
import 'security_question_verification_screen.dart';
import 'change_pin_screen.dart';

/// Screen for verifying caregiver PIN.
/// 
/// Used when PIN is required for:
/// - Editing pictoreeks
/// - Accessing settings
/// - Exiting client mode
class VerifyPinScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  final String? title;
  final String? subtitle;

  const VerifyPinScreen({
    super.key,
    this.onVerified,
    this.title,
    this.subtitle,
  });

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final PinService _pinService = PinService();
  bool _isVerifying = false;
  String? _errorMessage;

  /// Handle PIN verification
  Future<void> _onPinComplete(String pin) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _pinService.verifyPin(pin);

      if (isValid) {
        // PIN is correct
        if (widget.onVerified != null) {
          widget.onVerified!();
        } else {
          // Default: go back
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        // PIN is incorrect - show error and clear PIN
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Onjuiste pincode';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Onjuiste pincode';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    if (_isVerifying) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PinEntryScreen(
      title: widget.title ?? localizations.enterPin,
      subtitle: widget.subtitle ?? localizations.pinRequiredMessage,
      minLength: 4,
      maxLength: 4, // Exactly 4 digits
      showBackButton: true,
      errorMessage: _errorMessage,
      onPinComplete: _onPinComplete,
      onForgotPin: () async {
        // Get user email first
        final authService = AuthService();
        final user = authService.currentUser;
        
        if (user?.email != null) {
          // Navigate to security question verification screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecurityQuestionVerificationScreen(
                email: user!.email!,
                onVerificationSuccess: () {
                  // Verification successful - navigate to change PIN screen
                  // Pass forgotPin=true to skip current PIN entry
                  Navigator.of(context).pop(); // Close security question screen
                  Navigator.of(context).pop(); // Close verify PIN screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePinScreen(forgotPin: true),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          // No email available - show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('E-mailadres niet gevonden. Log opnieuw in.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}
