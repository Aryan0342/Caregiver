import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../routes/app_routes.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

/// Modern HomeScreen for the AAC pictogram routine app.
///
/// Matches the reference design with:
/// - Large header title with personalized welcome message
/// - Subtitle guiding users to create or open pictogram sets
/// - Two prominent action buttons (New Series, My Series)
/// - Settings icon in top right corner
/// - Clean, caregiver-friendly, child-safe UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    // Get user name from Firestore profile
    final user = FirebaseAuth.instance.currentUser;
    String userName = 'there';

    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('caregivers')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.exists == true) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            userName = data?['name'] ?? user.email?.split('@')[0] ?? 'there';
          } else {
            userName = user.email?.split('@')[0] ?? 'there';
          }

          return _buildHomeScreen(context, localizations, userName);
        },
      );
    }

    return _buildHomeScreen(context, localizations, userName);
  }

  Widget _buildHomeScreen(
      BuildContext context, AppLocalizations localizations, String userName) {
    final languageService = LanguageProvider.languageServiceOf(context);
    final flagEmoji =
        languageService.currentLanguage == AppLanguage.dutch ? '🇳🇱' : '🇺🇸';

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
                  // Language flag and settings button in top right
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _showLanguageSelector(context),
                        child: Text(
                          flagEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                ],
              ),
            ),

            // Main heading section: Welcome title and subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Welcome title with user name
                  Text(
                    '${localizations.welcomeMessage} $userName,',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle describing the actions - last 5 words italicized
                  _buildSubtitleWithPartialItalics(
                      context, localizations.guideSubtitle),
                ],
              ),
            ),

            // Main action buttons section - centered vertically
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 70),
                          // Primary action: client-based workflow
                          _buildInfoActionButton(
                            context,
                            icon: Icons.groups_rounded,
                            title: localizations.myClients,
                            subtitle: localizations.currentLanguage ==
                                    AppLanguage.dutch
                                ? 'voor zorgverleners'
                                : 'for care institutions',
                            color: AppTheme.primaryBlue,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.clients);
                            },
                          ),
                          const SizedBox(height: 28),

                          // Parent-focused entry point to the child workflow.
                          _buildInfoActionButton(
                            context,
                            icon: Icons.person_rounded,
                            title: localizations.currentLanguage ==
                                    AppLanguage.dutch
                                ? 'Mijn kind'
                                : 'My child',
                            subtitle: localizations.currentLanguage ==
                                    AppLanguage.dutch
                                ? 'Voor ouders'
                                : 'For parents',
                            color: AppTheme.accentOrange,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.myChild);
                            },
                          ),
                          const SizedBox(height: 18),

                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.pictoLibrary);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.library_books_rounded,
                                    color: AppTheme.primaryBlue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations.pictoLibrary,
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
            minHeight: 70,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
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

  Widget _buildInfoActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          constraints: const BoxConstraints(minHeight: 72),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            height: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleWithPartialItalics(BuildContext context, String text) {
    final words = text.split(' ');
    final regularWords =
        words.length > 5 ? words.sublist(0, words.length - 5) : <String>[];
    final italicWords =
        words.length > 5 ? words.sublist(words.length - 5) : words;

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.textSecondary,
          fontSize: 16,
          height: 1.5,
        );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (regularWords.isNotEmpty)
            TextSpan(text: '${regularWords.join(' ')} ', style: baseStyle),
          TextSpan(
            text: italicWords.join(' '),
            style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languageService =
        LanguageProvider.of(context)?.languageService ?? LanguageService();
    final localizations = LanguageProvider.localizationsOf(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.language, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(localizations.currentLanguage == AppLanguage.dutch
                ? 'Kies taal'
                : 'Choose language'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇳🇱', style: TextStyle(fontSize: 20)),
              title: const Text('Nederlands'),
              trailing: languageService.currentLanguage == AppLanguage.dutch
                  ? Icon(Icons.check, color: AppTheme.primaryBlue)
                  : null,
              onTap: () {
                languageService.setLanguage(AppLanguage.dutch);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 20)),
              title: const Text('English'),
              trailing: languageService.currentLanguage == AppLanguage.english
                  ? Icon(Icons.check, color: AppTheme.primaryBlue)
                  : null,
              onTap: () {
                languageService.setLanguage(AppLanguage.english);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
