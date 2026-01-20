import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';

/// Forgot password screen for caregivers.
/// 
/// Allows caregivers to reset password by entering their email.
/// Sends a password reset email with a link to reset the password on a web page.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Handle password reset - send email directly
  Future<void> _handlePasswordReset() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // Send password reset email using Firebase Auth
      print('Attempting to send password reset email to: $email');
      
      final result = await _authService.sendPasswordResetEmail(email);
      
      print('Password reset email result: success=${result.success}, error=${result.errorMessage}');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = result.success;
          if (!result.success) {
            _errorMessage = result.errorMessage ?? 'Fout bij verzenden van reset e-mail. Controleer of het e-mailadres bestaat in het systeem.';
          } else {
            // Success - clear any previous errors
            _errorMessage = null;
          }
        });
      }
    } catch (e, stackTrace) {
      // Log full error details for debugging
      print('Exception in _handlePasswordReset: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = false;
          _errorMessage = 'Fout bij verzenden van reset e-mail: $e. '
              'Controleer uw internetverbinding en of het e-mailadres correct is ingevoerd.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.resetPassword),
        backgroundColor: AppTheme.primaryBlueLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  localizations.resetPassword,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  localizations.enterEmailForReset,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_emailSent && !_isLoading,
                  decoration: InputDecoration(
                    labelText: localizations.emailAddress,
                    hintText: localizations.enterEmail,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 18),
                  onFieldSubmitted: (_) {
                    if (!_emailSent && !_isLoading) {
                      _handlePasswordReset();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.fieldRequired;
                    }
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return localizations.invalidEmail;
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Success message
                if (_emailSent)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.accentGreen,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.resetEmailSent,
                          style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Controleer uw inbox en klik op de link in de e-mail om uw wachtwoord te resetten op de webpagina.',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                
                // Send reset email button
                if (!_emailSent)
                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePasswordReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Verstuur reset e-mail',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                
                // Back to login button (show after email sent)
                if (_emailSent) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        localizations.login,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Back button (only show if email not sent)
                if (!_emailSent)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      localizations.back,
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
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
