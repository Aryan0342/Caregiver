import 'package:flutter/material.dart';

import '../providers/language_provider.dart';
import '../services/set_share_service.dart';
import '../theme.dart';

/// Asks for a share link and imports the shared pictogram set into the
/// current user's saved sets, reporting the result in a snackbar.
Future<void> showImportSetDialog(
  BuildContext context, [
  SetShareService? shareService,
]) async {
  final localizations = LanguageProvider.localizationsOf(context);
  final controller = TextEditingController();

  final token = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(localizations.importSet),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: localizations.pasteShareLink,
          prefixIcon: const Icon(Icons.link_rounded),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(localizations.importAction),
        ),
      ],
    ),
  );

  if (token == null || token.isEmpty) return;

  try {
    await (shareService ?? SetShareService()).importSharedSet(token);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.importSuccess),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${localizations.importFailed}: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
