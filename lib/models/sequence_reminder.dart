import 'package:timezone/timezone.dart' as tz;

/// One weekly schedule for a saved sequence, local to this device and account.
class SequenceReminder {
  const SequenceReminder({
    required this.userId,
    required this.setId,
    required this.setName,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.notificationBaseId,
    required this.enabled,
    required this.languageCode,
  });

  final String userId;
  final String setId;
  final String setName;
  final int hour;
  final int minute;
  final List<int> weekdays;
  final int notificationBaseId;
  final bool enabled;
  final String languageCode;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'setId': setId,
        'setName': setName,
        'hour': hour,
        'minute': minute,
        'weekdays': weekdays,
        'notificationBaseId': notificationBaseId,
        'enabled': enabled,
        'languageCode': languageCode,
      };

  factory SequenceReminder.fromJson(Map<String, dynamic> json) {
    return SequenceReminder(
      userId: json['userId'] as String,
      setId: json['setId'] as String,
      setName: json['setName'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      weekdays: List<int>.from(json['weekdays'] as List),
      notificationBaseId: json['notificationBaseId'] as int,
      enabled: json['enabled'] as bool,
      languageCode: json['languageCode'] as String,
    );
  }

  /// Construct calendar dates rather than adding 24-hour durations across DST.
  tz.TZDateTime nextOccurrence(tz.TZDateTime now, int weekday) {
    var daysAhead = (weekday - now.weekday + 7) % 7;
    var next = tz.TZDateTime(
        now.location, now.year, now.month, now.day + daysAhead, hour, minute);
    if (!next.isAfter(now)) {
      daysAhead += 7;
      next = tz.TZDateTime(
          now.location, now.year, now.month, now.day + daysAhead, hour, minute);
    }
    return next;
  }
}
