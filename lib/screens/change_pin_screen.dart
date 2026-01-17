import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../providers/language_provider.dart';
import 'pin_entry_screen.dart';

/// Screen for changing caregiver PIN.
/// 
/// Requires:
/// 1. Enter current PIN
/// 2. Enter new PIN
/// 3. Confirm new PIN
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final PinService _pinService = PinService();
  
  // Step tracking
  int _currentStep = 0; // 0: current PIN, 1: new PIN, 2: confirm PIN
  String? _newPin;
  String? _errorMessage;

  Future<void> _onCurrentPinComplete(String pin) async {
    // Verify current PIN
    final isValid = await _pinService.verifyPin(pin);
    
    if (isValid) {
      setState(() {
        _currentStep = 1;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = LanguageProvider.localizationsOf(context).incorrectPin;
      });
    }
  }

  void _onNewPinComplete(String pin) {
    setState(() {
      _newPin = pin;
      _currentStep = 2;
      _errorMessage = null;
    });
  }

  Future<void> _onConfirmPinComplete(String pin) async {
    if (pin != _newPin) {
      setState(() {
        _errorMessage = LanguageProvider.localizationsOf(context).pinsDoNotMatch;
      });
      return;
    }

    // Save new PIN
    try {
      await _pinService.savePin(pin);
      
      if (mounted) {
        final localizations = LanguageProvider.localizationsOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.pinChanged),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Navigate back to settings
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = LanguageProvider.localizationsOf(context).pinChangeError;
        });
      }
    }
  }

  void _handleBack() {
    if (_currentStep == 0) {
      // Go back to settings
      Navigator.of(context).pop();
    } else {
      // Go back to previous step
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    String title;
    String? subtitle;
    Function(String)? onPinComplete;

    switch (_currentStep) {
      case 0:
        title = localizations.currentPin;
        subtitle = localizations.enterPin;
        onPinComplete = _onCurrentPinComplete;
        break;
      case 1:
        title = localizations.newPin;
        subtitle = localizations.createPinDescription;
        onPinComplete = _onNewPinComplete;
        break;
      case 2:
        title = localizations.confirmNewPin;
        subtitle = localizations.confirmPin;
        onPinComplete = _onConfirmPinComplete;
        break;
      default:
        title = localizations.enterPin;
        onPinComplete = null;
    }

    return PinEntryScreen(
      key: ValueKey('pin_step_$_currentStep'), // Force new instance when step changes
      title: title,
      subtitle: subtitle,
      minLength: 4,
      maxLength: 4,
      showBackButton: true,
      errorMessage: _errorMessage,
      onPinComplete: onPinComplete,
      onBack: _handleBack,
    );
  }
}
