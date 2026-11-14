import 'package:caregiver/models/set_model.dart';
import 'package:caregiver/screens/sequence_reminder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('reminders default off and enabled reminders require a weekday',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
        home: SequenceReminderScreen(
      set: PictogramSet(
          id: 'morning',
          name: 'Morning routine',
          userId: 'alice',
          pictograms: const [],
          createdAt: DateTime(2026)),
    )));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(tester.widget<FilterChip>(find.byType(FilterChip).first).onSelected,
        isNull);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    for (var i = 0; i < 7; i++) {
      final chip = find.byType(FilterChip).at(i);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }
    final save = find.widgetWithText(FilledButton, 'Opslaan');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Selecteer minstens één dag.'), findsOneWidget);
  });
}
