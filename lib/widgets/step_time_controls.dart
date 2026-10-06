import 'package:flutter/material.dart';
import '../models/pictogram_model.dart';
import '../providers/language_provider.dart';
import '../services/step_notification_service.dart';
import '../theme.dart';

/// Formats minutes since midnight as "HH:mm".
String formatStepTime(int minutes) {
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final mins = (minutes % 60).toString().padLeft(2, '0');
  return '$hours:$mins';
}

/// Set-editor controls to give a step a planned time and turn its
/// notification on or off.
class StepTimeControls extends StatelessWidget {
  final Pictogram pictogram;
  final ValueChanged<Pictogram> onChanged;

  const StepTimeControls({
    super.key,
    required this.pictogram,
    required this.onChanged,
  });

  Future<void> _pickTime(BuildContext context) async {
    final minutes = pictogram.scheduledMinutes;
    final picked = await showTimePicker(
      context: context,
      // The keyboard entry mode overflows with the app's large button style,
      // so only the dial is offered.
      initialEntryMode: TimePickerEntryMode.dialOnly,
      initialTime: minutes != null
          ? TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60)
          : TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    onChanged(pictogram.copyWith(
      scheduledTime: formatStepTime(picked.hour * 60 + picked.minute),
    ));
  }

  Future<void> _toggleNotify(BuildContext context) async {
    if (pictogram.notify) {
      onChanged(pictogram.copyWith(notify: false));
      return;
    }
    final localizations = LanguageProvider.localizationsOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final allowed = await StepNotificationService.instance.requestPermission();
    onChanged(pictogram.copyWith(notify: true));
    if (!allowed) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(localizations.notificationsDenied),
          backgroundColor: AppTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    final minutes = pictogram.scheduledMinutes;
    final hasTime = minutes != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _pickTime(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasTime ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color:
                      hasTime ? AppTheme.primaryBlue : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  hasTime ? formatStepTime(minutes) : localizations.stepTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        hasTime ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  ),
                ),
                if (hasTime) ...[
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => onChanged(pictogram.copyWith(
                      clearScheduledTime: true,
                      notify: false,
                    )),
                    child: Tooltip(
                      message: localizations.removeTime,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasTime)
          SizedBox(
            width: 36,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              tooltip: pictogram.notify
                  ? localizations.notificationOn
                  : localizations.notificationOff,
              icon: Icon(
                pictogram.notify
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: pictogram.notify
                    ? AppTheme.accentOrange
                    : AppTheme.textSecondary,
              ),
              onPressed: () => _toggleNotify(context),
            ),
          ),
      ],
    );
  }
}
