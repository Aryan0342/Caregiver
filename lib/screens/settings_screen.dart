import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/language_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';
import '../services/auth_state_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsScreenContent();
  }
}

class _SettingsScreenContent extends StatefulWidget {
  const _SettingsScreenContent();

  @override
  State<_SettingsScreenContent> createState() => _SettingsScreenContentState();
}

class _SettingsScreenContentState extends State<_SettingsScreenContent> {

  /// Handle user logout with error handling.
  Future<void> _signOut(BuildContext context) async {
    try {
      // Clear login status so next time requires email/password login
      final authStateService = AuthStateService();
      await authStateService.clearLoginStatus();
      
      await FirebaseAuth.instance.signOut();
      
      // Navigate to login screen after logout
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false, // Remove all previous routes
        );
      }
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

  void _showLanguageSelector(BuildContext context) {
    final languageService = LanguageProvider.of(context)?.languageService ?? LanguageService();
    final localizations = LanguageProvider.localizationsOf(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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

  void _showAboutDialog(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Text(localizations.aboutApp),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(localizations.appSubtitle),
            const SizedBox(height: 16),
            Text(localizations.appDescription),
            const SizedBox(height: 16),
            Text(
              '${localizations.version} 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.pictogramsFrom,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
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

  void _showPrivacyDialog(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Text(localizations.privacy),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.privacyPolicy,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(localizations.privacyInfo1),
              const SizedBox(height: 16),
              Text(
                localizations.dataStorage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(localizations.privacyInfo2),
              Text(localizations.privacyInfo3),
              Text(localizations.privacyInfo4),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    final languageService = LanguageProvider.of(context)?.languageService ?? LanguageService();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Language selector
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.language,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(
                  localizations.languageLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(languageService.currentLanguage.displayName),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () => _showLanguageSelector(context),
              ),
            ),

            // Change PIN
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(
                  localizations.changePin,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(localizations.changePinDescription),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.changePin);
                },
              ),
            ),

            // Over de app (About the app)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(
                  localizations.aboutApp,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(localizations.versionInfo),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () => _showAboutDialog(context),
              ),
            ),

            // Privacy
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(
                  localizations.privacy,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(localizations.privacyInfo),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () => _showPrivacyDialog(context),
              ),
            ),

            // Logout
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  localizations.logout,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  languageService.currentLanguage == AppLanguage.dutch 
                    ? 'Uitloggen uit uw account' 
                    : 'Sign out of your account'
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () => _signOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
