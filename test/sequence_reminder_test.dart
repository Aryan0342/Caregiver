import 'package:caregiver/models/sequence_reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

SequenceReminder reminder({int hour = 8, int minute = 0}) => SequenceReminder(
      userId: 'caregiver',
      setId: 'morning',
      setName: 'Morning routine',
      hour: hour,
      minute: minute,
      weekdays: [1, 3, 5],
      notificationBaseId: 100000,
      enabled: true,
      languageCode: 'en',
    );

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('upcoming weekday uses the selected local wall time', () {
    final location = tz.getLocation('Asia/Karachi');
    final now = tz.TZDateTime(location, 2026, 11, 16, 7, 30); // Monday
    final next = reminder().nextOccurrence(now, DateTime.monday);
    expect(next, tz.TZDateTime(location, 2026, 11, 16, 8));
  });

  test('elapsed or exactly current time advances to next week', () {
    final location = tz.getLocation('Asia/Karachi');
    for (final minute in [0, 30]) {
      final next = reminder().nextOccurrence(
          tz.TZDateTime(location, 2026, 11, 16, 8, minute), DateTime.monday);
      expect(next, tz.TZDateTime(location, 2026, 11, 23, 8));
    }
  });

  test('Sunday to Monday wraps to the next calendar day', () {
    final location = tz.getLocation('Asia/Karachi');
    final next = reminder(hour: 15).nextOccurrence(
        tz.TZDateTime(location, 2026, 11, 15, 16), DateTime.monday);
    expect(next, tz.TZDateTime(location, 2026, 11, 16, 15));
  });

  test('weekly reminder keeps 08:00 across spring and autumn DST changes', () {
    final location = tz.getLocation('Europe/Amsterdam');
    for (final date in [DateTime(2026, 3, 28), DateTime(2026, 10, 24)]) {
      final now = tz.TZDateTime(location, date.year, date.month, date.day, 12);
      final next = reminder().nextOccurrence(now, DateTime.sunday);
      expect(next.day, date.day + 1);
      expect(next.weekday, DateTime.sunday);
      expect(next.hour, 8);
      expect(next.minute, 0);
      expect(next.timeZoneOffset, isNot(now.timeZoneOffset));
    }
  });

  test('stored reminder retains enabled state, account, time and weekdays', () {
    final original = reminder();
    final restored = SequenceReminder.fromJson(original.toJson());
    expect(restored.toJson(), original.toJson());
  });
}
