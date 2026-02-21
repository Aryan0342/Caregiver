import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'routes/app_routes.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_set_screen.dart';
import 'screens/my_sets_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/caregiver_registration_screen.dart';
import 'screens/caregiver_profile_setup_screen.dart';
import 'screens/create_caregiver_pin_screen.dart';
import 'screens/change_pin_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/security_question_verification_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/client_mode_entry_screen.dart';
import 'screens/request_picto_screen.dart';
import 'screens/profile_screen.dart';
import 'services/language_service.dart';
import 'services/setup_service.dart';
import 'services/pin_auth_service.dart';
import 'screens/verify_pin_screen.dart';
import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';

void main() async {
  // Required: Initialize Flutter bindings before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // CRITICAL PATH: Initialize Firebase - must be awaited for auth to work
  // This is required before runApp() because AuthWrapper uses FirebaseAuth
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // IMPORTANT: Disable Firestore offline persistence so the app always works online.
    // The client only uses the app with a network connection, so we explicitly
    // turn off local persistence and caching for Firestore.
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, // Disable offline persistence
      );
    } catch (e) {
      debugPrint('Firestore settings error: $e');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Start rendering immediately - Firestore settings will configure in background
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LanguageService _languageService;

  @override
  void initState() {
    super.initState();
    _languageService = LanguageService();
    _languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(_languageService.currentLanguage);

    return LanguageProvider(
      languageService: _languageService,
      localizations: localizations,
      child: MaterialApp(
        title: localizations.appName,
        theme: AppTheme.lightTheme,
        darkTheme: null, // No dark mode as requested
        debugShowCheckedModeBanner: false, // Remove DEBUG banner
        locale: _languageService.locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('nl', '')],
        // Use named routes
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const AuthWrapper(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.createSet: (context) => const CreateSetScreen(),
          AppRoutes.mySets: (context) => const MySetsScreen(),
          AppRoutes.settings: (context) => const SettingsScreen(),
          AppRoutes.caregiverRegistration: (context) =>
              const CaregiverRegistrationScreen(),
          AppRoutes.caregiverProfileSetup: (context) =>
              const CaregiverProfileSetupScreen(),
          AppRoutes.createCaregiverPin: (context) =>
              const CreateCaregiverPinScreen(),
          AppRoutes.changePin: (context) => const ChangePinScreen(),
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.resetPassword: (context) {
            final email =
                ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return ResetPasswordScreen(email: email);
          },
          AppRoutes.securityQuestionVerification: (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            final email = args?['email'] as String? ?? '';
            final onVerificationSuccess =
                args?['onVerificationSuccess'] as Function()? ?? () {};
            return SecurityQuestionVerificationScreen(
              email: email,
              onVerificationSuccess: onVerificationSuccess,
            );
          },
          AppRoutes.clientMode: (context) => const ClientModeEntryScreen(),
          AppRoutes.requestPicto: (context) => const RequestPictoScreen(),
          AppRoutes.emailVerification: (context) =>
              const EmailVerificationScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
        },
        // Fallback for unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const AuthWrapper());
        },
      ),
    );
  }
}

/// Wrapper widget that listens to authentication state and routes accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final SetupService _setupService = SetupService();
  final PinAuthService _pinAuthService = PinAuthService();
  bool _isCheckingSetup = false;
  bool _isCheckingPin = false;
  bool _shouldShowPin = false;
  bool _hasCheckedPin = false; // Track if we've initiated PIN check

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Clear PIN verification on app start to force check
    _pinAuthService.clearPinVerification();
    if (kDebugMode) {
      debugPrint('AuthWrapper: initState - cleared PIN verification');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App resumed - clear PIN verification to force check
      if (kDebugMode) {
        debugPrint('AuthWrapper: App resumed - clearing PIN verification');
      }
      _pinAuthService.clearPinVerification();
      // Reset check flag and trigger PIN check if user is logged in
      if (mounted && FirebaseAuth.instance.currentUser != null) {
        setState(() {
          _hasCheckedPin = false;
          _shouldShowPin = false;
        });
        _checkPinRequirement();
      }
    }
  }

  /// Check if PIN is required and update state
  Future<void> _checkPinRequirement() async {
    if (_isCheckingPin) return;

    setState(() {
      _isCheckingPin = true;
    });

    try {
      final pinRequired = await _pinAuthService.isPinRequired();

      if (mounted) {
        setState(() {
          _shouldShowPin = pinRequired;
          _isCheckingPin = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthWrapper: Error checking PIN requirement: $e');
      }
      if (mounted) {
        setState(() {
          _shouldShowPin = false;
          _isCheckingPin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          // FIRST CHECK: Email verification - block all access if not verified
          // Exception: Allow emailVerification screen itself
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (!user.emailVerified &&
              currentRoute != AppRoutes.emailVerification) {
            if (kDebugMode) {
              debugPrint(
                'AuthWrapper: Email not verified, routing to EmailVerificationScreen',
              );
            }
            // Reload user to get latest emailVerified status (in case user just verified)
            // Use Future.microtask to handle async reload without blocking
            Future.microtask(() async {
              try {
                await user.reload();
                final updatedUser = FirebaseAuth.instance.currentUser;
                if (mounted &&
                    updatedUser != null &&
                    updatedUser.emailVerified) {
                  // Email was verified - trigger rebuild to continue with normal flow
                  if (kDebugMode) {
                    debugPrint(
                      'AuthWrapper: Email verified after reload, continuing...',
                    );
                  }
                  setState(() {}); // Trigger rebuild to continue flow
                }
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('AuthWrapper: Error reloading user: $e');
                }
              }
            });
            // Show verification screen while checking
            return const EmailVerificationScreen();
          }

          // If on email verification screen but email is now verified, continue
          if (currentRoute == AppRoutes.emailVerification &&
              user.emailVerified) {
            // Email verified - navigate to profile setup or home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkSetupAndNavigate(context);
              }
            });
            return const SizedBox.shrink();
          }

          // Check PIN requirement on first build (only once)
          if (!_hasCheckedPin && !_isCheckingPin) {
            _hasCheckedPin = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkPinRequirement();
              }
            });
            // Show loading while checking
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If checking PIN, show loading
          if (_isCheckingPin) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If PIN is required, show PIN verification screen
          if (_shouldShowPin) {
            if (kDebugMode) {
              debugPrint('AuthWrapper: Showing PIN verification screen');
            }
            final localizations = LanguageProvider.localizationsOf(context);
            return VerifyPinScreen(
              title: localizations.enterPin,
              subtitle: localizations.pinRequiredMessage,
              onVerified: () async {
                // PIN verified - mark as verified and proceed
                if (kDebugMode) {
                  debugPrint('AuthWrapper: PIN verified, marking as verified');
                }
                await _pinAuthService.markPinVerified();
                if (mounted) {
                  setState(() {
                    _shouldShowPin = false;
                  });
                  _checkSetupAndNavigate(context);
                }
              },
            );
          }

          // PIN not required or already verified - proceed to home/setup
          // Check if we're already on a setup screen - don't interfere
          final routeAfterCheck = ModalRoute.of(context)?.settings.name;
          if (routeAfterCheck == AppRoutes.caregiverProfileSetup ||
              routeAfterCheck == AppRoutes.createCaregiverPin ||
              routeAfterCheck == AppRoutes.caregiverRegistration ||
              routeAfterCheck == AppRoutes.emailVerification) {
            return const SizedBox.shrink();
          }

          // If already on home screen, don't navigate again
          if (routeAfterCheck == AppRoutes.home) {
            return const HomeScreen();
          }

          // Check setup completion before navigating to home
          if (!_isCheckingSetup) {
            _isCheckingSetup = true;
            _checkSetupAndNavigate(context);
          }

          // Show loading while navigating
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }

  Future<void> _checkSetupAndNavigate(BuildContext context) async {
    if (!mounted) return;

    // Get current route and navigator before async operations
    final navigator = Navigator.of(context, rootNavigator: false);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Don't navigate if we're already on a setup screen or home
    if (currentRoute == AppRoutes.caregiverProfileSetup ||
        currentRoute == AppRoutes.createCaregiverPin ||
        currentRoute == AppRoutes.caregiverRegistration ||
        currentRoute == AppRoutes.home) {
      _isCheckingSetup = false;
      return;
    }

    // Small delay to allow any ongoing navigation to complete
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Check if setup is complete
    final isSetupComplete = await _setupService.isSetupComplete();

    if (!mounted) return;

    // Get route name after async (with mounted check)
    final routeAfterAsync =
        mounted ? ModalRoute.of(context)?.settings.name : null;

    // Only navigate to home if setup is complete and we're not already there
    if (isSetupComplete) {
      if (routeAfterAsync != AppRoutes.home && mounted) {
        navigator.pushReplacementNamed(AppRoutes.home);
      }
    } else {
      // Setup not complete - navigate to profile setup only if not already there
      if (routeAfterAsync != AppRoutes.caregiverProfileSetup &&
          routeAfterAsync != AppRoutes.createCaregiverPin &&
          routeAfterAsync != AppRoutes.caregiverRegistration &&
          mounted) {
        navigator.pushReplacementNamed(AppRoutes.caregiverProfileSetup);
      }
    }

    _isCheckingSetup = false;
  }
}
