import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/language_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../firebase_options.dart';

/// Flutter splash screen that handles app initialization.
/// 
/// This screen:
/// - Initializes Firebase and Firestore
/// - Shows logo, app name, tagline, and loading indicator
/// - Transitions to the main app once initialization is complete
class FlutterSplashScreen extends StatefulWidget {
  const FlutterSplashScreen({super.key});

  @override
  State<FlutterSplashScreen> createState() => _FlutterSplashScreenState();
}

class _FlutterSplashScreenState extends State<FlutterSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize Firebase and Firestore
  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Enable Firestore offline persistence
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Firestore offline persistence: $e');
        }
      }
      
      // Small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $e');
      }
      // Continue even if Firebase fails - let AuthWrapper handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        // Show splash screen while initializing
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildSplashContent();
        }
        
        // Initialization complete - transition to main app
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          }
        });
        
        return _buildSplashContent();
      },
    );
  }

  Widget _buildSplashContent() {
    final languageService = LanguageService();
    final localizations = AppLocalizations(languageService.currentLanguage);
    
    return LanguageProvider(
      languageService: languageService,
      localizations: localizations,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight, // Cream beige background
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // App Logo
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // App name
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
                  
                  // Subtitle
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
                  
                  const Spacer(flex: 3),
                  
                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue, // Muted grey-brown for loading
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
