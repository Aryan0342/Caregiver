import 'package:caregiver/services/step_countdown.dart';
import 'package:caregiver/theme.dart';
import 'package:caregiver/widgets/visual_step_timer.dart';
import 'package:caregiver/widgets/step_duration_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 420.0]) {
    testWidgets('visual timer shrinks, pauses and restarts at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final timer =
          StepCountdown(onElapsed: () {}, now: tester.binding.clock.now);
      addTearDown(timer.dispose);
      var configured = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
            body: Center(
                child: VisualStepTimer(
          countdown: timer,
          onConfigure: () => configured++,
        ))),
      ));
      await tester.tap(find.text('Timer'));
      expect(configured, 1);
      timer.start(const Duration(minutes: 10), autoAdvance: false);
      await tester.pump();
      expect(find.text('10:00'), findsOneWidget);
      expect(
          tester
              .widget<VisualTimerDial>(find.byType(VisualTimerDial))
              .remainingFraction,
          closeTo(1 / 6, .001));
      await tester.pump(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('05:00'), findsOneWidget);
      expect(
          tester
              .widget<VisualTimerDial>(find.byType(VisualTimerDial))
              .remainingFraction,
          closeTo(1 / 12, .002));
      await tester.tap(find.byTooltip('Timer pauzeren'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('Gepauzeerd'), findsOneWidget);
      await tester.tap(find.byTooltip('Timer herstarten'));
      await tester.pump();
      expect(find.text('10:00'), findsOneWidget);
      expect(timer.isUserPaused, isFalse);
      expect(tester.takeException(), isNull);
      timer.stop();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a timer can be configured and started directly during a session',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var completed = 0;
    final timer = StepCountdown(
        now: tester.binding.clock.now, onElapsed: () => completed++);
    addTearDown(timer.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
          body: Builder(
              builder: (context) => VisualStepTimer(
                    countdown: timer,
                    onConfigure: () async {
                      final config = await showStepTimerDialog(
                          context: context,
                          seconds: 600,
                          autoAdvance: true,
                          forSession: true);
                      if (config != null) {
                        timer.start(Duration(seconds: config.seconds!),
                            autoAdvance: config.autoAdvance);
                      }
                    },
                  ))),
    ));
    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '0');
    await tester.enterText(find.byType(TextField).at(1), '5');
    final start = find.text('Timer starten');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('00:05'), findsOneWidget);
    expect(find.byType(VisualTimerDial), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 1);
    expect(find.text('Tijd is om'), findsOneWidget);
    expect(tester.takeException(), isNull);
    timer.stop();
    await tester.pumpAndSettle();
  });
}
