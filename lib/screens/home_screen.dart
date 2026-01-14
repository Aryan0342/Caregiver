import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../routes/app_routes.dart';
import '../providers/language_provider.dart';

/// Modern HomeScreen for the AAC pictogram routine app.
/// 
/// Matches the reference design with:
/// - Large header title and subtitle
/// - Two prominent action buttons (New Series, My Series)
/// - Settings button at the bottom
/// - Clean, caregiver-friendly, child-safe UI
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Handle user logout with error handling.
  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigation will be handled by the auth state listener in main.dart
    } catch (e) {
      if (context.mounted) {
        final localizations = LanguageProvider.localizationsOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.logoutError),
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
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top section: Header with logout button
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Logout button in top right (subtle, not prominent)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: localizations.logout,
                    color: AppTheme.textSecondary,
                    onPressed: () => _signOut(context),
                  ),
                ],
              ),
            ),
            
            // Main heading section: Title and subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main title: "Pictoreeks Maken"
                  Text(
                    localizations.createPictogramSeries,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle: "Samen stap voor stap"
                  Text(
                    localizations.togetherStepByStep,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            
            // Main action buttons section - centered vertically
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Primary action: "Nieuwe pictoreeks" (Blue button)
                    _buildMainActionButton(
                      context,
                      icon: Icons.add_rounded,
                      title: localizations.newPictogramSet,
                      color: AppTheme.primaryBlue,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.createSet);
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Secondary action: "Mijn pictoreeksen" (Orange button)
                    _buildMainActionButton(
                      context,
                      icon: Icons.folder_rounded,
                      title: localizations.myPictogramSets,
                      color: AppTheme.accentOrange,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.mySets);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom section: Settings button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Center(
                  child: _buildSettingsButton(context, localizations),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a large, prominent action button for primary actions.
  /// 
  /// Features:
  /// - Full-width button with large touch target
  /// - Rounded corners (20px radius)
  /// - Subtle shadow for depth
  /// - Icon + text layout
  /// - Accessible size (minimum 64px height)
  Widget _buildMainActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          constraints: const BoxConstraints(
            minHeight: 80, // Large touch target for accessibility
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon (rounded Material icon)
              Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 20),
              // Button text
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the settings button at the bottom of the screen.
  /// 
  /// Smaller and less prominent than main action buttons.
  /// Uses a subtle, tappable design with gear icon.
  Widget _buildSettingsButton(BuildContext context, dynamic localizations) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.settings);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_rounded,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              localizations.settings,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
