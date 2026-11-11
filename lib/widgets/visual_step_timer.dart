import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/language_provider.dart';
import '../services/step_countdown.dart';
import 'step_duration_control.dart';

/// A clock-style countdown: red minutes disappear towards zero, just like
/// a physical visual timer. The clock scales beyond an hour for longer timers.
class VisualStepTimer extends StatelessWidget {
  const VisualStepTimer(
      {super.key, required this.countdown, required this.onConfigure});
  final StepCountdown countdown;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final strings = LanguageProvider.localizationsOf(context);
    return ListenableBuilder(
        listenable: countdown,
        builder: (context, _) {
          final duration = countdown.duration;
          if (duration == null) {
            return Center(
                child: OutlinedButton.icon(
              onPressed: onConfigure,
              icon: const Icon(Icons.timer_outlined, size: 20),
              label: Text(strings.pictogramTimer),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ));
          }
          final scaleSeconds = math.max(3600, duration.inSeconds);
          final fraction = (duration.inMilliseconds *
                  (1 - countdown.progress) /
                  (scaleSeconds * 1000))
              .clamp(0.0, 1.0);
          final timeText = formatStepDuration(countdown.remainingSeconds);
          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                    width: 104,
                    height: 104,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: fraction, end: fraction),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, value, _) => VisualTimerDial(
                        remainingFraction: value,
                        scaleMinutes: scaleSeconds ~/ 60,
                      ),
                    )),
                const SizedBox(width: 12),
                Flexible(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      countdown.hasElapsed
                          ? strings.timerFinished
                          : countdown.isUserPaused
                              ? strings.timerPaused
                              : strings.pictogramTimer,
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center),
                  Semantics(
                      label: strings.timeRemaining(timeText),
                      child: ExcludeSemantics(
                          child: Text(timeText,
                              style: const TextStyle(
                                  fontSize: 24,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ])))),
                  Wrap(alignment: WrapAlignment.center, children: [
                    _control(context,
                        icon: countdown.isUserPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        label: countdown.isUserPaused
                            ? strings.resumePictogramTimer
                            : strings.pausePictogramTimer,
                        onPressed: countdown.hasElapsed
                            ? null
                            : countdown.toggleUserPause),
                    _control(context,
                        icon: Icons.replay_rounded,
                        label: strings.restartPictogramTimer,
                        onPressed: () => countdown.start(duration)),
                    _control(context,
                        icon: Icons.tune_rounded,
                        label: strings.pictogramTimer,
                        onPressed: onConfigure),
                  ]),
                ])),
              ]));
        });
  }

  Widget _control(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback? onPressed}) {
    return SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 22,
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon),
        ));
  }
}

class VisualTimerDial extends StatelessWidget {
  const VisualTimerDial(
      {super.key, required this.remainingFraction, this.scaleMinutes = 60});
  final double remainingFraction;
  final int scaleMinutes;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _VisualTimerPainter(remainingFraction, scaleMinutes),
        child: const SizedBox.expand(),
      );
}

class _VisualTimerPainter extends CustomPainter {
  const _VisualTimerPainter(this.fraction, this.scaleMinutes);
  final double fraction;
  final int scaleMinutes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF414141)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final dialRadius = radius * .65;
    final sweep = -2 * math.pi * fraction.clamp(0.0, 1.0);
    if (fraction > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: dialRadius),
          -math.pi / 2, sweep, true, Paint()..color = const Color(0xFFE53945));
    }
    for (var tick = 0; tick < 60; tick++) {
      final angle = -math.pi / 2 + tick * math.pi / 30;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final major = tick % 5 == 0;
      canvas.drawLine(
          center + direction * (radius - (major ? 8 : 5)),
          center + direction * (radius - 3),
          Paint()
            ..color = const Color(0xFF555555)
            ..strokeWidth = major ? 1.3 : .7);
      if (major) {
        final number =
            tick == 0 ? 0 : ((60 - tick) * scaleMinutes / 60).round();
        final text = TextPainter(
            text: TextSpan(
                text: '$number',
                style: TextStyle(
                    color: const Color(0xFF222222),
                    fontSize: radius * .19,
                    fontWeight: FontWeight.w700)),
            textDirection: TextDirection.ltr)
          ..layout();
        final location = center + direction * radius * .77;
        text.paint(canvas, location - Offset(text.width / 2, text.height / 2));
      }
    }
    final handAngle = -math.pi / 2 + sweep;
    canvas.drawLine(
        center,
        center + Offset(math.cos(handAngle), math.sin(handAngle)) * dialRadius,
        Paint()
          ..color = const Color(0xFF333333)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF333333));
  }

  @override
  bool shouldRepaint(_VisualTimerPainter oldDelegate) =>
      fraction != oldDelegate.fraction ||
      scaleMinutes != oldDelegate.scaleMinutes;
}
