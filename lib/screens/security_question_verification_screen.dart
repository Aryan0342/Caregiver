import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/caregiver_profile_service.dart';
import '../providers/language_provider.dart';

/// Screen for verifying security question.
/// 
/// Used when user forgot password or PIN.
/// Displays the user's security question and verifies the answer.
class SecurityQuestionVerificationScreen extends StatefulWidget {
  final String email;
  final Function() onVerificationSuccess;

  const SecurityQuestionVerificationScreen({
    super.key,
    required this.email,
    required this.onVerificationSuccess,
  });

  @override
  State<SecurityQuestionVerificationScreen> createState() => _SecurityQuestionVerificationScreenState();
}

class _SecurityQuestionVerificationScreenState extends State<SecurityQuestionVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();
  final _profileService = CaregiverProfileService();
  
  String? _securityQuestion;
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSecurityQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  /// Load security question for the user
  Future<void> _loadSecurityQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final question = await _profileService.getSecurityQuestionByEmail(widget.email);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (question == null || question.isEmpty) {
            _errorMessage = 'Geen beveiligingsvraag gevonden voor dit e-mailadres. '
                'Zorg ervoor dat u een profiel heeft aangemaakt met een beveiligingsvraag.';
          } else {
            _securityQuestion = question;
            _errorMessage = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Fout bij laden beveiligingsvraag: $e';
        });
      }
    }
  }

  /// Verify security answer
  Future<void> _verifyAnswer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _profileService.verifySecurityAnswerByEmail(
        widget.email,
        _answerController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        if (isValid) {
          // Verification successful - call callback
          widget.onVerificationSuccess();
        } else {
          // Incorrect answer
          setState(() {
            _errorMessage = LanguageProvider.localizationsOf(context).incorrectSecurityAnswer;
            _answerController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Fout bij verifiëren antwoord. Probeer het opnieuw.';
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
        title: Text(localizations.verifySecurityQuestion),
        backgroundColor: AppTheme.primaryBlueLight,
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
                  Icons.security,
                  size: 80,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  localizations.verifySecurityQuestion,
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
                  localizations.answerSecurityQuestion,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                
                // Security question display
                if (!_isLoading && _securityQuestion != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: AppTheme.primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localizations.securityQuestion,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _securityQuestion!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Answer field
                if (!_isLoading && _securityQuestion != null)
                  TextFormField(
                    controller: _answerController,
                    enabled: !_isVerifying,
                    decoration: InputDecoration(
                      labelText: localizations.securityAnswer,
                      hintText: localizations.enterSecurityAnswer,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceWhite,
                    ),
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 18),
                    onFieldSubmitted: (_) => _verifyAnswer(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.securityAnswerRequired;
                      }
                      if (value.trim().length < 3) {
                        return localizations.securityAnswerTooShort;
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
                
                // Verify button
                if (!_isLoading && _securityQuestion != null)
                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              localizations.verifySecurityQuestion,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Back button
                TextButton(
                  onPressed: _isVerifying ? null : () => Navigator.of(context).pop(),
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