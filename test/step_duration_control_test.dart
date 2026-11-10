import 'package:caregiver/models/pictogram_model.dart';
import 'package:caregiver/theme.dart';
import 'package:caregiver/widgets/step_duration_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'duration can be saved and cleared without changing the clock time',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var pictogram = const Pictogram(
        id: 1,
        keyword: 'Care',
        category: 'Care',
        imageUrl: '',
        scheduledTime: '08:00');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
          body: StatefulBuilder(
        builder: (context, setState) => Center(
            child: StepDurationControl(
                pictogram: pictogram,
                onChanged: (updated) => setState(() => pictogram = updated))),
      )),
    ));
    await tester.tap(find.text('Duur'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '0');
    await tester.enterText(find.byType(TextField).at(1), '0');
    final save = find.text('Opslaan');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(pictogram.durationSeconds, isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextField).at(0));
    await tester.enterText(find.byType(TextField).at(0), '2');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(pictogram.durationSeconds, 125);
    expect(pictogram.autoAdvanceAfterTimer, isFalse);
    expect(pictogram.scheduledTime, '08:00');
    expect(find.text('Duur: 02:05'), findsOneWidget);
    await tester.tap(find.byTooltip('Duur verwijderen'));
    await tester.pumpAndSettle();
    expect(pictogram.durationSeconds, isNull);
    expect(pictogram.scheduledTime, '08:00');
    expect(tester.takeException(), isNull);
  });
}
