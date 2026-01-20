import 'package:flutter/material.dart';
import '../theme.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';

/// Modern, elegant splash screen shown on app launch.
/// 
/// Features:
/// - Gradient background with app colors
/// - Animated logo and text
/// - Smooth fade-in transitions
/// - Auto-navigation to auth flow
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller with very fast animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // No fade-in - start fully visible immediately
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    // Logo already at full size - no scale animation needed
    _scaleAnimation = Tween<double>(
      begin: 1.0, // Start at full size
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    // Text already in position - no slide animation
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero, // Already in position
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    // Start animation immediately (though nothing animates)
    _animationController.forward();

    // Navigate after minimal delay
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Minimal delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      // Navigate to auth wrapper (which handles login/PIN flow)
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.login,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight, // Cream beige background
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // App Logo with scale animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // App name with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        localizations.appName,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary, // Dark grey-brown text
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.appSubtitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary, // Muted grey-brown text
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Loading indicator
                SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue, // Muted grey-brown for loading
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
