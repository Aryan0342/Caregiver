import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../routes/app_routes.dart';
import '../services/biometric_auth_service.dart';
import '../services/biometric_preference_service.dart';
import '../services/language_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final BiometricAuthService _biometricAuthService = BiometricAuthService();
  final BiometricPreferenceService _biometricPreferenceService =
      BiometricPreferenceService();

  bool _faceIdEnabled = false;
  bool _isBusy = false;
  bool _isFaceIdAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
    _loadAvailableBiometrics();
  }

  Future<void> _loadPreference() async {
    final enabled = await _biometricPreferenceService.isFaceIdEnabled();
    if (!mounted) return;
    setState(() {
      _faceIdEnabled = enabled;
    });
  }

  Future<void> _loadAvailableBiometrics() async {
    final isSupported = await _biometricAuthService.isDeviceSupported();
    if (!isSupported) return;
    final types = await _biometricAuthService.getAvailableBiometrics();
    if (!mounted) return;
    setState(() {
      _isFaceIdAvailable = _isFaceIdCapable(types);
    });
  }

  Future<void> _handleToggle(bool value) async {
    if (_isBusy) return;
    if (value && !_isFaceIdAvailable) {
      _showSnack(
          'Face ID not supported on this device.', AppTheme.accentOrange);
      return;
    }
    if (!value) {
      await _biometricPreferenceService.setFaceIdEnabled(false);
      if (!mounted) return;
      setState(() {
        _faceIdEnabled = false;
      });
      _showSnack(
        LanguageProvider.localizationsOf(context).currentLanguage ==
                AppLanguage.dutch
            ? 'Face ID is uitgeschakeld'
            : 'Face ID disabled',
        AppTheme.accentOrange,
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _enableFaceId();
    });
  }

  Future<void> _enableFaceId() async {
    setState(() {
      _isBusy = true;
    });

    final localizations = LanguageProvider.localizationsOf(context);
    final isSupported = await _biometricAuthService.isDeviceSupported();
    final canCheck = await _biometricAuthService.canCheckBiometrics();
    final types = await _biometricAuthService.getAvailableBiometrics();

    if (!mounted) return;

    if (!isSupported) {
      _showSnack(
        localizations.currentLanguage == AppLanguage.dutch
            ? 'Biometrie is niet beschikbaar op dit apparaat'
            : 'Biometrics are not available on this device',
        AppTheme.accentOrange,
      );
      setState(() {
        _isBusy = false;
      });
      return;
    }

    if (!canCheck) {
      _showSnack(
        localizations.currentLanguage == AppLanguage.dutch
            ? 'Geen Face ID ingesteld op dit apparaat'
            : 'No Face ID enrolled on this device',
        AppTheme.accentOrange,
      );
      setState(() {
        _isBusy = false;
      });
      return;
    }

    if (types.isEmpty) {
      _showSnack(
        localizations.currentLanguage == AppLanguage.dutch
            ? 'Geen Face ID ingesteld op dit apparaat'
            : 'No Face ID enrolled on this device',
        AppTheme.accentOrange,
      );
      setState(() {
        _isBusy = false;
      });
      return;
    }

    if (!_isFaceIdCapable(types)) {
      _showSnack(
          'Face ID not supported on this device.', AppTheme.accentOrange);
      setState(() {
        _isBusy = false;
      });
      return;
    }

    final reason = _reasonForBiometric(localizations);

    final result = await _biometricAuthService.authenticate(reason: reason);
    if (!mounted) return;

    if (result.status == BiometricAuthStatus.notEnrolled) {
      _showSnack(
        localizations.currentLanguage == AppLanguage.dutch
            ? 'Geen Face ID gevonden. Voeg Face ID toe in de instellingen van uw telefoon.'
            : 'No Face ID found on this device. Please add Face ID in Phone Settings.',
        AppTheme.accentOrange,
      );
      setState(() {
        _isBusy = false;
      });
      return;
    }

    if (result.status == BiometricAuthStatus.notAvailable) {
      _showSnack(
        localizations.currentLanguage == AppLanguage.dutch
            ? 'Biometrie is niet beschikbaar op dit apparaat'
            : 'Biometrics are not available on this device',
        AppTheme.accentOrange,
      );
      setState(() {
        _isBusy = false;
      });
      return;
    }

    if (result.status == BiometricAuthStatus.lockedOut ||
        result.status == BiometricAuthStatus.permanentlyLockedOut) {
      _showSnack(
        localizations.currentLanguage == AppLanguage.dutch
            ? 'Te veel pogingen. Probeer later opnieuw.'
            : 'Too many attempts. Try again later.',
        Colors.red,
      );
      setState(() {
        _isBusy = false;
      });
      return;
    }

    if (!result.isSuccess) {
      _showSnack(
        localizations.currentLanguage == AppLanguage.dutch
            ? 'Face ID verificatie mislukt'
            : 'Face ID verification failed',
        Colors.red,
      );
      setState(() {
        _isBusy = false;
      });
      return;
    }

    await _biometricPreferenceService.setFaceIdEnabled(true);

    if (!mounted) return;
    setState(() {
      _faceIdEnabled = true;
      _isBusy = false;
    });
    _showSnack(
      'Face ID Enabled',
      AppTheme.accentGreen,
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _biometricToggleLabel(AppLanguage language) {
    if (language == AppLanguage.dutch) {
      return 'Biometrisch slot inschakelen';
    }
    return 'Enable biometric lock';
  }

  IconData _biometricToggleIcon() {
    return Icons.face;
  }

  bool _isFaceIdCapable(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return true;
    }
    if (kIsWeb) {
      return false;
    }
    if (Platform.isAndroid) {
      final hasFingerprint = types.contains(BiometricType.fingerprint);
      final hasFaceLike = types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak);
      return hasFaceLike && !hasFingerprint;
    }
    return false;
  }

  String _reasonForBiometric(AppLocalizations localizations) {
    if (localizations.currentLanguage == AppLanguage.dutch) {
      return 'Bevestig met Face ID';
    }
    return 'Confirm with Face ID';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    final languageService =
        LanguageProvider.of(context)?.languageService ?? LanguageService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          languageService.currentLanguage == AppLanguage.dutch
              ? 'Beveiliging'
              : 'Security',
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(
                  localizations.changePin,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(localizations.changePinDescription),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.changePin);
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isFaceIdAvailable
                  ? SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _biometricToggleIcon(),
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      title: Text(
                        _biometricToggleLabel(
                          languageService.currentLanguage,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        languageService.currentLanguage == AppLanguage.dutch
                            ? 'Open de app met Face ID of pincode'
                            : 'Unlock the app with Face ID or PIN',
                      ),
                      value: _faceIdEnabled,
                      onChanged: _isBusy ? null : _handleToggle,
                    )
                  : ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.face,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      title: Text(
                        languageService.currentLanguage == AppLanguage.dutch
                            ? 'Face ID niet ondersteund op dit apparaat.'
                            : 'Face ID not supported on this device.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
