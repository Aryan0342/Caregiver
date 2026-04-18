import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../routes/app_routes.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../services/set_service.dart';
import 'pictogram_picker_screen.dart';
import 'client_mode_session_screen.dart';

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
  final SetService _setService = SetService();

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
                          _buildMainActionButton(
                            context,
                            icon: Icons.groups_rounded,
                            title: localizations.myClients,
                            color: AppTheme.primaryBlue,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.clients);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Secondary action: "Nieuwe pictoreeks" (Blue button)
                          _buildMainActionButton(
                            context,
                            icon: Icons.add_rounded,
                            title: localizations.newPictogramSet,
                            color: AppTheme.accentOrange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PictogramPickerScreen(
                                    maxSelection: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Tertiary action: "Opgeslagen pictoreeksen" (Orange button)
                          _buildMainActionButton(
                            context,
                            icon: Icons.folder_rounded,
                            title: localizations.myPictogramSets,
                            color: AppTheme.primaryBlue,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.mySets);
                            },
                          ),
                          const SizedBox(height: 42),

                          // Bottom quick actions: active sets (left) + library (right)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.16),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildBottomTextAction(
                                    context,
                                    icon: Icons.flash_on_rounded,
                                    title: localizations.activePictogramSets,
                                    onTap: () {
                                      _openActiveSetChooser();
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _buildBottomTextAction(
                                    context,
                                    icon: Icons.library_books_rounded,
                                    title: localizations.pictoLibrary,
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, AppRoutes.pictoLibrary);
                                    },
                                  ),
                                ),
                              ],
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

  Widget _buildBottomTextAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final iconSize = compact ? 20.0 : 22.0;
        final fontSize = compact ? 12.0 : 13.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppTheme.primaryBlue, size: iconSize),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openActiveSetChooser() async {
    final localizations = LanguageProvider.localizationsOf(context);
    final allSets = await _setService.getUserSetsOnce(includeAutoSaved: true);
    final activeSets = allSets.where((set) => set.isAutoSaved).take(5).toList();

    if (!mounted) return;

    if (activeSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.noAutoSavedSets),
          backgroundColor: AppTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedSet = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.activePictogramSets,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeSets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (itemContext, index) {
                      final set = activeSets[index];
                      final displayName = set.name.trim().isEmpty
                          ? '${localizations.recentAutoSaved} ${index + 1}'
                          : set.name;
                      final subtitleParts = <String>[
                        '${set.pictograms.length} picto\'s',
                        if (set.clientName != null &&
                            set.clientName!.isNotEmpty)
                          set.clientName!,
                      ];

                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primaryBlue.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.flash_on_rounded,
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        title: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        subtitle: Text(
                          subtitleParts.join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        trailing: Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppTheme.accentGreen,
                          size: 26,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext, set);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSet == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientModeSessionScreen(set: selectedSet),
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

  /// Build subtitle text with only the last 5 words italicized
  Widget _buildSubtitleWithPartialItalics(BuildContext context, String text) {
    final words = text.split(' ');
    final regularWords =
        words.length > 5 ? words.sublist(0, words.length - 5) : [];
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
            TextSpan(
              text: '${regularWords.join(' ')} ',
              style: baseStyle,
            ),
          TextSpan(
            text: italicWords.join(' '),
            style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Show language selector dialog
  void _showLanguageSelector(BuildContext context) {
    final languageService =
        LanguageProvider.of(context)?.languageService ?? LanguageService();
    final localizations = LanguageProvider.localizationsOf(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.language, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Text(localizations.languageLabel),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((language) {
            return RadioListTile<AppLanguage>(
              title: Text(language.displayName),
              value: language,
              groupValue: languageService.currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  languageService.setLanguage(value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryBlue,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localizations.close,
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}
