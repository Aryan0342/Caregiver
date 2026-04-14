import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/pin_service.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/biometric_preference_service.dart';
import '../services/language_service.dart';
import '../services/pin_auth_service.dart';
import '../l10n/app_localizations.dart';
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
  static const String _hasBeenAskedBiometricKey =
      'has_been_asked_biometric_login';

  final PinService _pinService = PinService();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();
  final BiometricPreferenceService _biometricPreferenceService =
      BiometricPreferenceService();
  final PinAuthService _pinAuthService = PinAuthService();
  bool _isVerifying = false;
  bool _isBiometricChecking = false;
  bool _hasAttemptedBiometric = false;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = <BiometricType>[];
  IconData? _biometricIcon;
  String? _biometricLabel;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBiometricFlow();
    });
  }

  Future<void> _initializeBiometricFlow() async {
    final isSupported = await _biometricAuthService.isDeviceSupported();
    final canCheck = await _biometricAuthService.canCheckBiometrics();
    final available = await _biometricAuthService.getAvailableBiometrics();
    final supportsBiometric =
        isSupported && canCheck && _supportsAnyBiometric(available);

    if (!supportsBiometric || !mounted) {
      await _loadBiometricUi();
      return;
    }

    _availableBiometrics = available;
    await _showFirstTimeBiometricPromptIfNeeded();
    if (!mounted) return;

    await _loadBiometricUi();
    await _tryBiometric();
  }

  Future<void> _showFirstTimeBiometricPromptIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasBeenAsked = prefs.getBool(_hasBeenAskedBiometricKey) ?? false;
    if (hasBeenAsked || !mounted) return;

    final localizations = LanguageProvider.localizationsOf(context);
    final actionLabel = _biometricActionLabel(localizations);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDutch = localizations.currentLanguage == AppLanguage.dutch;
        return AlertDialog(
          title: Text(
            isDutch
                ? '$actionLabel inschakelen?'
                : 'Enable $actionLabel Login?',
          ),
          content: Text(
            isDutch
                ? 'Wilt u $actionLabel gebruiken om sneller in te loggen? U kunt altijd terugvallen op uw pincode.'
                : 'Would you like to use $actionLabel for faster login? You can always use your PIN as backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(isDutch ? 'Nee' : 'No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isDutch ? 'Ja' : 'Yes'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result != true) {
      await prefs.setBool(_hasBeenAskedBiometricKey, true);
      return;
    }

    await prefs.setBool(_hasBeenAskedBiometricKey, true);
    final reason = _reasonForBiometric(localizations);
    final authResult = await _biometricAuthService.authenticate(reason: reason);

    if (authResult.isSuccess) {
      await _biometricPreferenceService.setFaceIdEnabled(true);
    }
  }

  Future<void> _loadBiometricUi() async {
    final enabled = await _biometricPreferenceService.isFaceIdEnabled();
    if (!mounted) return;

    final available = await _biometricAuthService.getAvailableBiometrics();
    if (!mounted) return;
    final hasBiometric = _supportsAnyBiometric(available);
    if (!hasBiometric) {
      setState(() {
        _biometricEnabled = false;
        _availableBiometrics = <BiometricType>[];
        _biometricIcon = null;
        _biometricLabel = null;
      });
      return;
    }

    final localizations = LanguageProvider.localizationsOf(context);

    setState(() {
      _availableBiometrics = available;
      _biometricEnabled = enabled;
      _biometricIcon = _iconForBiometric();
      _biometricLabel = _labelForBiometric(localizations);
    });
  }

  Future<void> _tryBiometric() async {
    if (_hasAttemptedBiometric) return;
    _hasAttemptedBiometric = true;

    final shouldSkip = await _pinAuthService.shouldSkipFaceId();
    if (shouldSkip || !mounted) return;

    final enabled = await _biometricPreferenceService.isFaceIdEnabled();
    if (!enabled || !mounted) return;

    final isSupported = await _biometricAuthService.isDeviceSupported();
    final canCheck = await _biometricAuthService.canCheckBiometrics();
    final available = await _biometricAuthService.getAvailableBiometrics();
    final hasBiometric = _supportsAnyBiometric(available);
    if (!isSupported || !canCheck || !hasBiometric || !mounted) return;

    _availableBiometrics = available;

    setState(() {
      _isBiometricChecking = true;
    });

    final localizations = LanguageProvider.localizationsOf(context);
    final reason = _reasonForBiometric(localizations);

    final result = await _biometricAuthService.authenticate(reason: reason);
    if (!mounted) return;

    setState(() {
      _isBiometricChecking = false;
    });

    if (result.status == BiometricAuthStatus.lockedOut ||
        result.status == BiometricAuthStatus.permanentlyLockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.currentLanguage == AppLanguage.dutch
                ? 'Te veel pogingen. Probeer later opnieuw.'
                : 'Too many attempts. Try again later.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (result.isSuccess) {
      await _pinAuthService.setSkipFaceId(false);
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      await _pinAuthService.setSkipFaceId(true);
    }
  }

  IconData _iconForBiometric() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.lock;
  }

  String _labelForBiometric(AppLocalizations localizations) {
    final action = _biometricActionLabel(localizations);
    final isDutch = localizations.currentLanguage == AppLanguage.dutch;
    return isDutch ? '$action ingeschakeld' : '$action enabled';
  }

  String _reasonForBiometric(AppLocalizations localizations) {
    final action = _biometricActionLabel(localizations);
    final isDutch = localizations.currentLanguage == AppLanguage.dutch;
    return isDutch ? 'Ontgrendel met $action' : 'Unlock with $action';
  }

  String _biometricActionLabel(AppLocalizations localizations) {
    final isDutch = localizations.currentLanguage == AppLanguage.dutch;
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return isDutch ? 'Vingerafdruk' : 'Fingerprint';
    }
    return isDutch ? 'Biometrie' : 'Biometric';
  }

  bool _supportsAnyBiometric(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return true;
    }
    if (types.contains(BiometricType.fingerprint)) {
      return true;
    }
    if (types.contains(BiometricType.strong)) {
      return true;
    }
    if (types.contains(BiometricType.weak)) {
      return true;
    }
    if (types.contains(BiometricType.iris)) {
      return true;
    }
    return false;
  }

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
      biometricIcon: _biometricEnabled ? _biometricIcon : null,
      biometricLabel: _biometricEnabled ? _biometricLabel : null,
      showUsePinButton: _biometricEnabled && _isBiometricChecking,
      onUsePin: () async {
        await _biometricAuthService.stopAuthentication();
        await _pinAuthService.setSkipFaceId(true);
        if (!mounted) return;
        setState(() {
          _isBiometricChecking = false;
        });
      },
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
                      builder: (context) =>
                          const ChangePinScreen(forgotPin: true),
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
