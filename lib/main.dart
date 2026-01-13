import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'routes/app_routes.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_set_screen.dart';
import 'screens/my_sets_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    // Offline persistence may already be enabled or not supported on this platform
    // This is fine - Firestore will use default settings
    debugPrint('Firestore offline persistence: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dag in beeld',
      theme: AppTheme.lightTheme,
      darkTheme: null, // No dark mode as requested
      // Use named routes
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const AuthWrapper(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.createSet: (context) => const CreateSetScreen(),
        AppRoutes.mySets: (context) => const MySetsScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
      // Fallback for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        );
      },
    );
  }
}

/// Wrapper widget that listens to authentication state and routes accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, go to home screen
        if (snapshot.hasData && snapshot.data != null) {
          // Use a post-frame callback to navigate after the build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != AppRoutes.home) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            }
          });
          // Return home screen while transitioning
          return const HomeScreen();
        }

        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}
