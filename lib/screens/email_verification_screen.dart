import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';
import '../services/language_service.dart';

/// Email verification screen.
/// 
/// Shows after registration and blocks app progression until email is verified.
/// Allows resending verification email with cooldown to prevent spam.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isCheckingVerification = false;
  bool _isResendingEmail = false;
  DateTime? _lastResendTime;
  int _resendCooldownSeconds = 30;

  @override
  void initState() {
    super.initState();
    // Send verification email automatically when screen loads if user is not verified
    _sendVerificationEmailIfNeeded();
  }

  /// Send verification email automatically if user is not verified
  Future<void> _sendVerificationEmailIfNeeded() async {
    final user = _authService.currentUser;
    if (user != null && !user.emailVerified) {
      // Send verification email automatically (silently, no UI feedback needed)
      await _authService.sendEmailVerification();
    }
  }

  /// Check if email is verified by reloading user and checking status
  Future<void> _checkVerification() async {
    setState(() {
      _isCheckingVerification = true;
    });

    try {
      // Reload user to get latest emailVerified status
      final reloadResult = await _authService.reloadUser();
      
      if (!reloadResult.success) {
        if (mounted) {
          final localizations = LanguageProvider.localizationsOf(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reloadResult.errorMessage ?? localizations.error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        setState(() {
          _isCheckingVerification = false;
        });
        return;
      }

      // Check verification status
      final user = _authService.currentUser;
      
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });

        if (user != null && user.emailVerified) {
          // Email verified - show success and navigate
          final localizations = LanguageProvider.localizationsOf(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.emailVerifiedSuccess),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Navigate to profile setup (or home if setup complete)
          // AuthWrapper will handle the correct routing
          Navigator.pushReplacementNamed(context, AppRoutes.caregiverProfileSetup);
        } else {
          // Email not verified - show warning
          final localizations = LanguageProvider.localizationsOf(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.emailNotVerified),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
        final localizations = LanguageProvider.localizationsOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.error}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Handle wrong email - show dialog and allow sign out
  Future<void> _handleWrongEmail() async {
    final localizations = LanguageProvider.localizationsOf(context);
    
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.wrongEmail),
        content: Text(localizations.wrongEmailMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.signOutAndRegister),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      // Sign out and delete the account
      try {
        final user = _authService.currentUser;
        if (user != null) {
          // Delete the user account (requires recent login, but since they just registered, it should work)
          await user.delete();
          debugPrint('Account with wrong email deleted');
        }
        // Sign out
        await _authService.signOut();
        
        if (mounted) {
          // Navigate to registration screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.caregiverRegistration,
            (route) => false,
          );
        }
      } catch (e) {
        // If deletion fails (e.g., requires recent login), just sign out
        debugPrint('Error deleting account: $e');
        await _authService.signOut();
        
        if (mounted) {
          final localizations = LanguageProvider.localizationsOf(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.error}: $e'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Navigate to login screen instead
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      }
    }
  }

  /// Resend verification email with cooldown
  Future<void> _resendVerificationEmail() async {
    // Check cooldown
    if (_lastResendTime != null) {
      final secondsSinceLastResend = DateTime.now().difference(_lastResendTime!).inSeconds;
      if (secondsSinceLastResend < _resendCooldownSeconds) {
        final localizations = LanguageProvider.localizationsOf(context);
        final languageService = LanguageProvider.languageServiceOf(context);
        final remainingSeconds = _resendCooldownSeconds - secondsSinceLastResend;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.resendEmailCooldown} ($remainingSeconds ${languageService.currentLanguage == AppLanguage.dutch ? 'seconden' : 'seconds'})'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isResendingEmail = true;
    });

    try {
      final result = await _authService.sendEmailVerification();
      
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
          _lastResendTime = DateTime.now();
        });

        final localizations = LanguageProvider.localizationsOf(context);
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.emailResentSuccess),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? localizations.emailVerificationError),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
        final localizations = LanguageProvider.localizationsOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.emailVerificationError}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    final user = _authService.currentUser;
    final userEmail = user?.email ?? '';

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(localizations.verifyYourEmail),
          backgroundColor: AppTheme.primaryBlueLight,
          foregroundColor: Colors.white,
          elevation: 0,
          // No back button - user must verify email
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  localizations.verificationEmailSentTitle,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  localizations.verificationEmailSent,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Email address (highlighted)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // "I've verified my email" button
                SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isCheckingVerification ? null : _checkVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isCheckingVerification
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            localizations.iveVerifiedMyEmail,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Resend email button
                SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    onPressed: _isResendingEmail ? null : _resendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isResendingEmail
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : Text(
                            localizations.resendEmail,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Wrong email option
                Center(
                  child: TextButton(
                    onPressed: _handleWrongEmail,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: Text(
                      localizations.wrongEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
