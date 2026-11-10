import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pictogram_model.dart';
import '../providers/language_provider.dart';

String formatStepDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

class StepTimerConfiguration {
  const StepTimerConfiguration(
      {required this.seconds, required this.autoAdvance});
  final int? seconds;
  final bool autoAdvance;
}

Future<StepTimerConfiguration?> showStepTimerDialog({
  required BuildContext context,
  required int seconds,
  required bool autoAdvance,
  bool forSession = false,
  bool canRemove = false,
}) {
  return showDialog<StepTimerConfiguration>(
      context: context,
      builder: (_) => _DurationDialog(
          seconds: seconds,
          autoAdvance: autoAdvance,
          forSession: forSession,
          canRemove: canRemove));
}

class StepDurationControl extends StatelessWidget {
  const StepDurationControl(
      {super.key, required this.pictogram, required this.onChanged});
  final Pictogram pictogram;
  final ValueChanged<Pictogram> onChanged;

  Future<void> _pick(BuildContext context) async {
    final result = await showStepTimerDialog(
        context: context,
        seconds: pictogram.durationSeconds ?? 60,
        autoAdvance: pictogram.autoAdvanceAfterTimer);
    if (result != null) {
      onChanged(pictogram.copyWith(
          durationSeconds: result.seconds,
          autoAdvanceAfterTimer: result.autoAdvance));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LanguageProvider.localizationsOf(context);
    final seconds = pictogram.durationSeconds;
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined, size: 16),
              const SizedBox(width: 4),
              Text(
                  seconds == null
                      ? strings.stepDuration
                      : '${strings.stepDuration}: ${formatStepDuration(seconds)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ])),
      ),
      if (seconds != null)
        SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              tooltip: strings.removeDuration,
              icon: const Icon(Icons.close),
              onPressed: () =>
                  onChanged(pictogram.copyWith(clearDuration: true)),
            )),
    ]);
  }
}

class _DurationDialog extends StatefulWidget {
  const _DurationDialog(
      {required this.seconds,
      required this.autoAdvance,
      this.forSession = false,
      this.canRemove = false});
  final int seconds;
  final bool autoAdvance;
  final bool forSession;
  final bool canRemove;
  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late final TextEditingController _minutes;
  late final TextEditingController _seconds;
  String? _error;
  late bool _autoAdvance;

  @override
  void initState() {
    super.initState();
    _minutes = TextEditingController(text: '${widget.seconds ~/ 60}');
    _seconds = TextEditingController(text: '${widget.seconds % 60}');
    _autoAdvance = widget.autoAdvance;
  }

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LanguageProvider.localizationsOf(context);
    return AlertDialog(
      scrollable: true,
      title: Text(
          widget.forSession ? strings.pictogramTimer : strings.stepDuration),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (widget.forSession)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(strings.sessionTimerHint)),
        TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4)
            ],
            decoration: InputDecoration(labelText: strings.durationMinutes)),
        const SizedBox(height: 16),
        TextField(
            controller: _seconds,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2)
            ],
            decoration: InputDecoration(labelText: strings.durationSeconds)),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.autoAdvance),
          subtitle: Text(strings.autoAdvanceDescription),
          value: _autoAdvance,
          onChanged: (value) => setState(() => _autoAdvance = value),
        ),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
      ]),
      actions: [
        if (widget.canRemove)
          TextButton(
              onPressed: () => Navigator.pop(
                  context,
                  StepTimerConfiguration(
                      seconds: null, autoAdvance: _autoAdvance)),
              child: Text(strings.removeDuration)),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel)),
        TextButton(
            onPressed: () {
              final minutes = int.tryParse(_minutes.text) ?? 0;
              final seconds = int.tryParse(_seconds.text) ?? 0;
              final total = minutes * 60 + seconds;
              if (seconds > 59 || total < 1 || total > 86400) {
                setState(() => _error = strings.invalidDuration);
                return;
              }
              Navigator.pop(
                  context,
                  StepTimerConfiguration(
                      seconds: total, autoAdvance: _autoAdvance));
            },
            child: Text(widget.forSession
                ? strings.startPictogramTimer
                : strings.save)),
      ],
    );
  }
}
