import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showOfflineModeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            const Text('Offline modus'),
          ],
        ),
        content: const Text(
          'Pictogrammen worden automatisch opgeslagen voor offline gebruik. '
          'U kunt de app gebruiken zonder internetverbinding zodra de pictogrammen zijn geladen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Sluiten',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
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
            const Text('Over de app'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dag in beeld',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Pictoreeksen'),
            const SizedBox(height: 16),
            const Text(
              'Een app voor het maken en gebruiken van pictogramreeksen '
              'voor dagelijkse routines en zorgcommunicatie.',
            ),
            const SizedBox(height: 16),
            Text(
              'Versie 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pictogrammen van ARASAAC',
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
              'Sluiten',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
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
            const Text('Privacy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacybeleid',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Uw gegevens worden veilig opgeslagen en alleen gebruikt voor de functionaliteit van de app.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Gegevensopslag:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Pictogramreeksen worden opgeslagen in Firebase'),
              const Text('• Alleen u heeft toegang tot uw eigen reeksen'),
              const Text('• Geen gegevens worden gedeeld met derden'),
              const SizedBox(height: 16),
              const Text(
                'Offline gebruik:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Pictogrammen worden lokaal opgeslagen voor snelle toegang'),
              const Text('• U kunt de app offline gebruiken'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Sluiten',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Instellingen'),
        backgroundColor: AppTheme.primaryBlueLight,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Taal (Language) - locked to Dutch
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.language,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: const Text(
                  'Taal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Nederlands'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                onTap: () {
                  // Show info that language is locked
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Taal is ingesteld op Nederlands'),
                      backgroundColor: AppTheme.primaryBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Offline modus (Offline mode) - info only
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cloud_off,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: const Text(
                  'Offline modus',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Pictogrammen worden automatisch opgeslagen'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () => _showOfflineModeInfo(context),
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
                    color: AppTheme.primaryBlueLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: const Text(
                  'Over de app',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Versie en informatie'),
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
                    color: AppTheme.primaryBlueLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: const Text(
                  'Privacy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Privacybeleid en gegevens'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () => _showPrivacyDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
