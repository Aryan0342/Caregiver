import 'package:flutter/material.dart';

/// Keep both dial and digital entry usable with the app's large button theme.
/// The fixed-height Material time dialog needs its standard action sizes;
/// otherwise Cancel and OK wrap and overflow in digital entry mode.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    // The stock Dutch validation sentence wraps past the input dialog's
    // fixed height. Keep the message short in both supported languages.
    errorInvalidText: Localizations.localeOf(context).languageCode == 'nl'
        ? 'Ongeldige tijd'
        : 'Invalid time',
    builder: (context, child) => Theme(
      // Standard picker typography and input padding also leave room for
      // localized validation messages. Preserve the app's colors.
      data: ThemeData(
        useMaterial3: Theme.of(context).useMaterial3,
        colorScheme: Theme.of(context).colorScheme,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    ),
  );
}
