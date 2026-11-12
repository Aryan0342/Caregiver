import 'package:caregiver/theme.dart';
import 'package:caregiver/widgets/app_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [360.0, 420.0]) {
    for (final language in ['en', 'nl']) {
      testWidgets('digital picker fits $language at width $width with keyboard',
          (tester) async {
        tester.view.physicalSize = Size(width, 910);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        TimeOfDay? selected;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          locale: Locale(language),
          supportedLocales: const [Locale('en'), Locale('nl')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                        onPressed: () async {
                          selected = await showAppTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 8, minute: 0));
                        },
                        child: const Text('Choose time'),
                      ))),
        ));
        await tester.tap(find.text('Choose time'));
        await tester.pumpAndSettle();
        final strings = MaterialLocalizations.of(
            tester.element(find.byType(TimePickerDialog)));
        await tester.tap(find.byTooltip(strings.inputTimeModeButtonLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField).at(0), '99');
        await tester.tap(find.text(strings.okButtonLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TimePickerDialog), findsOneWidget);
        await tester.enterText(find.byType(TextField).at(0), '15');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.tap(find.text(strings.okButtonLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(selected, const TimeOfDay(hour: 15, minute: 30));
      });
    }
  }
}
