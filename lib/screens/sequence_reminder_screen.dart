import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/set_model.dart';
import '../providers/language_provider.dart';
import '../services/sequence_reminder_service.dart';
import '../services/step_notification_service.dart';
import '../theme.dart';
import '../widgets/app_time_picker.dart';

class SequenceReminderScreen extends StatefulWidget {
  const SequenceReminderScreen({super.key, required this.set});
  final PictogramSet set;

  @override
  State<SequenceReminderScreen> createState() => _SequenceReminderScreenState();
}

class _SequenceReminderScreenState extends State<SequenceReminderScreen> {
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reminder = await SequenceReminderService.instance
          .getForSet(widget.set.userId, widget.set.id);
      if (!mounted) return;
      setState(() {
        if (reminder != null) {
          _enabled = reminder.enabled;
          _time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
          _days
            ..clear()
            ..addAll(reminder.weekdays);
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LanguageProvider.localizationsOf(context).reminderSaveFailed;
      });
    }
  }

  Future<void> _save() async {
    final strings = LanguageProvider.localizationsOf(context);
    if (_enabled && _days.isEmpty) {
      setState(() => _error = strings.reminderSelectDays);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_enabled &&
          !await StepNotificationService.instance.requestPermission()) {
        if (mounted) setState(() => _error = strings.reminderPermissionNeeded);
        return;
      }
      if (FirebaseAuth.instance.currentUser?.uid != widget.set.userId) return;
      await SequenceReminderService.instance.save(
        userId: widget.set.userId,
        setId: widget.set.id,
        setName: widget.set.name,
        hour: _time.hour,
        minute: _time.minute,
        weekdays: _days.toList(),
        enabled: _enabled,
        languageCode: strings.currentLanguage.code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.reminderSaved)));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is StateError
            ? e.message.toString()
            : strings.reminderSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LanguageProvider.localizationsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.routineReminder)),
      backgroundColor: AppTheme.backgroundLight,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Text(widget.set.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(strings.routineReminderDescription),
              const SizedBox(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.enableRoutineReminder),
                value: _enabled,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _enabled = value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(strings.reminderTime),
                trailing: Text(_time.format(context),
                    style: Theme.of(context).textTheme.titleLarge),
                enabled: _enabled && !_saving,
                onTap: () async {
                  final time = await showAppTimePicker(
                      context: context, initialTime: _time);
                  if (time != null && mounted) setState(() => _time = time);
                },
              ),
              const SizedBox(height: 16),
              Text(strings.reminderDays,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(strings.reminderWeekdays[i]),
                    selected: _days.contains(i + 1),
                    labelStyle: TextStyle(
                      color: _days.contains(i + 1) && _enabled && !_saving
                          ? AppTheme.surfaceWhite
                          : AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    color: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return states.contains(WidgetState.disabled)
                            ? AppTheme.warmTan
                            : AppTheme.darkGreyBrown;
                      }
                      return AppTheme.surfaceWhite;
                    }),
                    checkmarkColor: _enabled && !_saving
                        ? AppTheme.surfaceWhite
                        : AppTheme.textPrimary,
                    side: BorderSide(
                      color: _days.contains(i + 1)
                          ? AppTheme.darkGreyBrown
                          : AppTheme.mutedGreyBrown,
                    ),
                    onSelected: !_enabled || _saving
                        ? null
                        : (selected) => setState(() {
                              selected ? _days.add(i + 1) : _days.remove(i + 1);
                              _error = null;
                            }),
                  ),
              ]),
              Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                      onPressed: !_enabled || _saving
                          ? null
                          : () => setState(() {
                                _days
                                  ..clear()
                                  ..addAll([1, 2, 3, 4, 5, 6, 7]);
                              }),
                      child: Text(strings.reminderEveryDay))),
              const SizedBox(height: 16),
              Text(strings.reminderDeviceNote,
                  style: Theme.of(context).textTheme.bodySmall),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(strings.save),
              ),
            ]),
    );
  }
}
