import 'package:flutter/material.dart';
import '../theme.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';
import '../services/setup_service.dart';

/// Welcome screen shown on first app launch.
/// 
/// Shows two options:
/// 1. "Ik ben verzorger" (I am a caregiver) - Always enabled
/// 2. "Start met cliënt" (Start with client) - Disabled until setup complete
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final SetupService _setupService = SetupService();
  bool _isCheckingSetup = true;
  bool _isSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final isComplete = await _setupService.isSetupComplete();
    if (mounted) {
      setState(() {
        _isSetupComplete = isComplete;
        _isCheckingSetup = false;
      });
    }
  }

  void _handleCaregiverOption() {
    // Navigate to login/registration
    if (_setupService.isAuthenticated()) {
      // Already logged in, go to home
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      // Not logged in, go to login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<void> _handleClientOption() async {
    if (!_isSetupComplete) {
      // If not complete, button is disabled, so nothing happens
      return;
    }

    // Navigate directly to client mode (PIN already verified at app startup)
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.clientMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                  MediaQuery.of(context).padding.top - 
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App logo
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),

                  // App name
                  Text(
                    localizations.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.appSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Option 1: "Ik ben verzorger" (Always enabled)
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton.icon(
                      onPressed: _handleCaregiverOption,
                      icon: const Icon(Icons.person_outline, size: 28),
                      label: Text(
                        localizations.iAmCaregiver,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option 2: "Start met cliënt" (Disabled until setup complete)
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton.icon(
                      onPressed: _isSetupComplete ? _handleClientOption : null,
                      icon: const Icon(Icons.child_care_outlined, size: 28),
                      label: Text(
                        localizations.startWithClient,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSetupComplete
                            ? AppTheme.accentOrange
                            : AppTheme.textSecondary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.textSecondary.withValues(alpha: 0.3),
                        disabledForegroundColor: AppTheme.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Info text when client mode is disabled
                  if (!_isSetupComplete && !_isCheckingSetup) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localizations.clientModeDisabledMessage,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
