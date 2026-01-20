import 'package:flutter/material.dart';
import '../theme.dart';
import '../routes/app_routes.dart';
import '../providers/language_provider.dart';

/// Modern HomeScreen for the AAC pictogram routine app.
/// 
/// Matches the reference design with:
/// - Large header title and subtitle
/// - Two prominent action buttons (New Series, My Series)
/// - Settings icon in top right corner
/// - Clean, caregiver-friendly, child-safe UI
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top section: Header with logo and settings button
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo on left top
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  // Settings button in top right
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: localizations.settings,
                    color: AppTheme.textSecondary,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),
                ],
              ),
            ),
            
            // Main heading section: Title only
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 48.0),
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
                    
                    // Secondary action: "Opgeslagen pictoreeksen" (Orange button)
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          constraints: const BoxConstraints(
            minHeight: 70, // Smaller touch target
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon (rounded Material icon)
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              // Button text
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
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

}
