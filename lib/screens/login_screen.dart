import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../config/test_credentials.dart';
import '../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Attempt login
    final result = await _authService.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!result.success && mounted) {
      setState(() {
        _errorMessage = result.errorMessage;
      });
      
      // Show error message
      final localizations = LanguageProvider.localizationsOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? localizations.errorOccurred),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    // If successful, navigation will be handled by the auth state listener in main.dart
  }

  /// Handle test login - creates account if needed, then logs in
  Future<void> _handleTestLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fill in test credentials
    _emailController.text = TestCredentials.testEmail;
    _passwordController.text = TestCredentials.testPassword;

    // First, try to create the test account (if it doesn't exist)
    var createResult = await _authService.createUserWithEmailAndPassword(
      email: TestCredentials.testEmail,
      password: TestCredentials.testPassword,
    );

    // If account already exists, that's fine - just proceed to login
    if (!createResult.success && 
        createResult.errorMessage?.contains('al een account') != true) {
      // If it's not an "already exists" error, show it
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final localizations = LanguageProvider.localizationsOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(createResult.errorMessage ?? localizations.errorCreatingTestAccount),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    // Now try to log in
    final loginResult = await _authService.signInWithEmailAndPassword(
      email: TestCredentials.testEmail,
      password: TestCredentials.testPassword,
    );

    setState(() {
      _isLoading = false;
    });

    final localizations = LanguageProvider.localizationsOf(context);
    if (!loginResult.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginResult.errorMessage ?? localizations.errorTestLogin),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.successTestLogin),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    // Navigation will be handled by the auth state listener in main.dart
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.health_and_safety,
                    size: 100,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    localizations.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    localizations.appSubtitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Email field - Large input field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: localizations.emailAddress,
                      hintText: localizations.enterEmail,
                      prefixIcon: const Icon(Icons.email_outlined, size: 28),
                      errorText: _errorMessage?.contains('e-mail') == true 
                          ? _errorMessage 
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.enterEmail;
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return localizations.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Password field - Large input field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: localizations.password,
                      hintText: localizations.enterPassword,
                      prefixIcon: const Icon(Icons.lock_outlined, size: 28),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      errorText: _errorMessage?.contains('wachtwoord') == true 
                          ? _errorMessage 
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.enterPassword;
                      }
                      if (value.length < 6) {
                        return localizations.passwordMinLength;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 32),
                  
                  // Login button - Large button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 64),
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
                            localizations.login,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Test Login button - For development/testing
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleTestLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(color: AppTheme.accentGreen, width: 2),
                    ),
                    icon: Icon(
                      Icons.bug_report_outlined,
                      color: AppTheme.accentGreen,
                    ),
                    label: Text(
                      localizations.testLogin,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.testAccountLabel}: ${TestCredentials.testEmail}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
