import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/auth_state_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';

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
  final _authStateService = AuthStateService();
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
    } else if (result.success) {
      // Mark that user has logged in (for PIN auth on next app open)
      // This must be called before navigation to ensure it's saved
      await _authStateService.markLoggedIn();
      
      if (kDebugMode) {
        debugPrint('LoginScreen: Marked user as logged in');
      }
    }
    // If successful, navigation will be handled by the auth state listener in main.dart
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.textPrimary,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
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
                  
                  // Forgot Password button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context, AppRoutes.forgotPassword);
                            },
                      child: Text(
                        localizations.forgotPassword,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Register button
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamed(context, AppRoutes.caregiverRegistration);
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                    child: Text(
                      localizations.createAccount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
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
