import 'package:caregiver/services/step_countdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manual default waits at zero; enabling auto completes only once',
      (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.start(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    expect(timer.remainingSeconds, 0);
    expect(timer.hasElapsed, isTrue);
    expect(completed, 0);
    timer.setAutoAdvance(true);
    timer.setAutoAdvance(true);
    expect(completed, 1);
  });

  testWidgets('auto advance happens exactly once and never early',
      (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.setAutoAdvance(true);
    timer.start(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1750));
    expect(completed, 0);
    expect(timer.remainingSeconds, 1);
    await tester.pump(const Duration(milliseconds: 250));
    expect(completed, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(completed, 1);
  });

  testWidgets('manual navigation replaces the previous step deadline',
      (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.setAutoAdvance(true);
    timer.start(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    timer.start(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 0);
    expect(timer.remainingSeconds, 4);
    await tester.pump(const Duration(seconds: 4));
    expect(completed, 1);
  });

  testWidgets('untimed steps and stopped sessions do not advance',
      (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.setAutoAdvance(true);
    timer.start(null);
    await tester.pump(const Duration(hours: 1));
    expect(completed, 0);
    timer.start(const Duration(seconds: 1));
    timer.stop();
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 0);
  });

  testWidgets('dialogs pause and resume the remaining duration',
      (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.setAutoAdvance(true);
    timer.start(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
    timer.pause();
    await tester.pump(const Duration(minutes: 1));
    expect(timer.remainingSeconds, 3);
    expect(completed, 0);
    timer.resume();
    await tester.pump(const Duration(seconds: 3));
    expect(completed, 1);
  });

  testWidgets(
      'background expiry advances once on return without skipping unseen steps',
      (tester) async {
    var index = 0;
    late StepCountdown timer;
    timer = StepCountdown(
        now: tester.binding.clock.now,
        onElapsed: () {
          index++;
          timer.start(const Duration(seconds: 3));
        });
    addTearDown(timer.dispose);
    timer.setAutoAdvance(true);
    timer.start(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    timer.setForeground(false);
    await tester.pump(const Duration(minutes: 5));
    expect(index, 0);
    timer.setForeground(true);
    expect(index, 1);
    expect(timer.remainingSeconds, 3);
    await tester.pump(const Duration(seconds: 3));
    expect(index, 2);
    timer.stop();
  });

  testWidgets('turning automatic completion off prevents advancement',
      (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.setAutoAdvance(true);
    timer.start(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    timer.setAutoAdvance(false);
    await tester.pump(const Duration(seconds: 3));
    expect(completed, 0);
    expect(timer.hasElapsed, isTrue);
  });

  testWidgets('last timed step finishes without creating another timer',
      (tester) async {
    var finished = false;
    late StepCountdown timer;
    timer = StepCountdown(
        now: tester.binding.clock.now,
        onElapsed: () {
          finished = true;
          timer.stop();
        });
    addTearDown(timer.dispose);
    timer.setAutoAdvance(true);
    timer.start(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(finished, isTrue);
    expect(timer.duration, isNull);
    await tester.pump(const Duration(seconds: 5));
    expect(timer.duration, isNull);
  });

  testWidgets('disposing a session cancels its timer', (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    timer.setAutoAdvance(true);
    timer.start(const Duration(seconds: 1));
    timer.dispose();
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 0);
  });

  testWidgets('a user-paused timer stays paused after a settings dialog closes',
      (tester) async {
    final timer =
        StepCountdown(onElapsed: () {}, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.start(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 2));
    timer.toggleUserPause();
    timer.pause();
    await tester.pump(const Duration(seconds: 20));
    timer.resume();
    expect(timer.isUserPaused, isTrue);
    expect(timer.remainingSeconds, 8);
    await tester.pump(const Duration(seconds: 20));
    expect(timer.remainingSeconds, 8);
    timer.toggleUserPause();
    await tester.pump(const Duration(seconds: 8));
    expect(timer.hasElapsed, isTrue);
  });

  testWidgets('each pictogram chooses its own automatic completion policy',
      (tester) async {
    var completed = 0;
    final timer = StepCountdown(
        onElapsed: () => completed++, now: tester.binding.clock.now);
    addTearDown(timer.dispose);
    timer.start(const Duration(seconds: 1), autoAdvance: false);
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 0);
    timer.start(const Duration(seconds: 3), autoAdvance: true);
    expect(completed, 0);
    await tester.pump(const Duration(seconds: 3));
    expect(completed, 1);
    timer.start(const Duration(seconds: 1), autoAdvance: false);
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 1);
  });
}
