import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/pin_service.dart';
import '../services/setup_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';
import 'pin_entry_screen.dart';

/// Screen for creating a new caregiver PIN.
/// 
/// First-time PIN setup after registration.
/// Requires entering PIN twice for confirmation.
class CreateCaregiverPinScreen extends StatefulWidget {
  const CreateCaregiverPinScreen({super.key});

  @override
  State<CreateCaregiverPinScreen> createState() => _CreateCaregiverPinScreenState();
}

class _CreateCaregiverPinScreenState extends State<CreateCaregiverPinScreen> {
  final PinService _pinService = PinService();
  final SetupService _setupService = SetupService();
  String? _firstPin;
  bool _isConfirming = false;
  bool _isSaving = false;
  String? _errorMessage;

  /// Handle first PIN entry
  void _onFirstPinComplete(String pin) {
    // Validate PIN length (exactly 4 digits)
    if (pin.length != 4) {
      setState(() {
        _errorMessage = 'PIN moet precies 4 cijfers zijn';
      });
      return;
    }

    setState(() {
      _firstPin = pin;
      _isConfirming = true;
      _errorMessage = null;
    });
  }

  /// Handle back button - go back to profile setup if confirming, otherwise go back normally
  void _handleBack() {
    if (_isConfirming) {
      // If confirming, go back to first PIN entry
      setState(() {
        _isConfirming = false;
        _firstPin = null;
        _errorMessage = null;
      });
    } else {
      // If on first PIN entry, go back to profile setup
      Navigator.of(context).pop();
    }
  }

  /// Handle PIN confirmation
  Future<void> _onConfirmPinComplete(String pin) async {
    if (_firstPin == null) {
      return;
    }

    // Check if PINs match
    if (pin != _firstPin) {
      setState(() {
        _errorMessage = 'Pincodes komen niet overeen';
        _isConfirming = false;
        _firstPin = null;
      });
      return;
    }

    // Save PIN
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _pinService.savePin(pin);
      
      // Mark setup as complete
      await _setupService.markSetupComplete();

      if (mounted) {
        final localizations = LanguageProvider.localizationsOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.pinCreated),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isConfirming = false;
        _firstPin = null;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    if (_isSaving) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PinEntryScreen(
      key: ValueKey(_isConfirming ? 'confirm' : 'create'), // Force new instance when step changes
      title: _isConfirming ? localizations.confirmPin : localizations.createPin,
      subtitle: _isConfirming 
          ? null 
          : localizations.createPinDescription,
      minLength: 4,
      maxLength: 4, // Exactly 4 digits
      showBackButton: true, // Always show back button
      errorMessage: _errorMessage,
      onPinComplete: _isConfirming ? _onConfirmPinComplete : _onFirstPinComplete,
      onBack: _handleBack, // Custom back handler
    );
  }
}
