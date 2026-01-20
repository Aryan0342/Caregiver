import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';

/// Reset password screen.
/// 
/// Allows users to set a new password after security question verification.
class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _authService = AuthService();

  bool _isResetting = false;
  String? _errorMessage;

  @override
  void dispose() {
    super.dispose();
  }

  /// Handle password reset
  /// 
  /// Note: Firebase Auth client SDK requires email verification for password reset.
  /// For a completely email-free solution, implement Firebase Admin SDK on backend
  /// or use deep link handler to capture action code automatically.
  Future<void> _handlePasswordReset() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    setState(() {
      _isResetting = true;
    });

    try {
      // Send password reset email
      // Note: The password will be set when user clicks the email link
      // We don't need the password here since Firebase requires it to be entered
      // on the web page after clicking the email link
      final result = await _authService.sendPasswordResetEmail(widget.email);

      if (mounted) {
        setState(() {
          _isResetting = false;
        });

        if (result.success) {
          // Password reset email sent successfully
          // Note: User must click the link in email and enter password there
          // Show warning dialog explaining they need to check email
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('E-mail verzonden'),
                content: const Text(
                  'We hebben een wachtwoord reset e-mail naar uw inbox gestuurd.\n\n'
                  'BELANGRIJK: U moet op de link in de e-mail klikken en daar uw nieuwe wachtwoord invoeren.\n\n'
                  'Het wachtwoord wordt pas gewijzigd nadat u de link heeft geklikt en het wachtwoord op de webpagina heeft ingevoerd.\n\n'
                  'Let op: Het wachtwoord dat u hier invoerde wordt niet gebruikt. U moet het nieuwe wachtwoord invoeren op de webpagina nadat u op de e-mail link klikt.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = result.errorMessage;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResetting = false;
          _errorMessage = 'Fout bij resetten van wachtwoord: $e';
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
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(localizations.resetPassword),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  localizations.resetPassword,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Info box explaining the process
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBlue,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Wachtwoord Reset Proces',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Klik op de knop hieronder om een reset e-mail te versturen\n\n'
                        '2. Controleer uw inbox voor de reset e-mail\n\n'
                        '3. Klik op de link in de e-mail\n\n'
                        '4. Voer uw nieuwe wachtwoord in op de webpagina\n\n'
                        '5. Log in met uw nieuwe wachtwoord',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // Send reset email button
                ElevatedButton(
                  onPressed: _isResetting ? null : _handlePasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isResetting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verstuur reset e-mail',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
