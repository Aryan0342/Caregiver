import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/pin_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';
import 'pin_entry_screen.dart';

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
      onForgotPin: () {
        // Navigate to change PIN screen
        Navigator.pushNamed(context, AppRoutes.changePin);
      },
    );
  }
}
