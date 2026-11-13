import 'dart:convert';
import 'package:caregiver/models/pictogram_model.dart';
import 'package:caregiver/services/sequence_reminder_service.dart';
import 'package:caregiver/services/step_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final pending = <int, Map<String, dynamic>>{};
  final scheduled = <Map<String, dynamic>>[];
  final service = SequenceReminderService.instance;
  setUpAll(AndroidFlutterLocalNotificationsPlugin.registerWith);

  Future<void> save(String setId,
          {bool enabled = true, List<int> days = const [1, 3, 5]}) =>
      service.save(
        userId: 'alice',
        setId: setId,
        setName: setId,
        hour: 8,
        minute: 0,
        weekdays: days,
        enabled: enabled,
        languageCode: 'en',
      );

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    pending.clear();
    scheduled.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'), (_) async => 'Asia/Karachi');
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return null;
        case 'canScheduleExactNotifications':
          return true;
        case 'pendingNotificationRequests':
          return pending.values.toList();
        case 'cancel':
          pending.remove((call.arguments as Map)['id'] as int);
          return null;
        case 'zonedSchedule':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          scheduled.add(args);
          pending[args['id'] as int] = args;
          return null;
      }
      return null;
    });
    await service.synchronizeAccount('alice');
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('each selected weekday repeats and routes to its own sequence',
      () async {
    await save('morning');
    await save('evening', days: [2, 4]);
    expect(pending.length, 5);
    expect(pending.keys.toSet().length, 5);
    for (final notification in scheduled) {
      expect(notification['matchDateTimeComponents'], isNotNull);
      final payload = notification['payload'] as String;
      final data = jsonDecode(payload.substring('sequence:'.length)) as Map;
      expect(data['userId'], 'alice');
      expect(data['setId'], anyOf('morning', 'evening'));
    }
    expect((await service.getForSet('alice', 'morning'))!.weekdays, [1, 3, 5]);
  });

  test('editing replaces old weekdays and disabling removes all repeats',
      () async {
    await save('morning');
    await save('morning', days: [6, 7]);
    expect(pending.length, 2);
    await save('morning', enabled: false, days: [6, 7]);
    expect(pending, isEmpty);
    expect((await service.getForSet('alice', 'morning'))!.enabled, isFalse);
  });

  test('step cancellation never removes a routine reminder', () async {
    await save('morning');
    await StepNotificationService.instance.scheduleForSteps(
      steps: [
        const Pictogram(
            id: 1,
            keyword: 'Step',
            category: 'test',
            imageUrl: '',
            scheduledTime: '23:59',
            notify: true)
      ],
      currentIndex: 0,
      setName: 'morning',
      channelName: 'Steps',
      titleFor: (p) => p.keyword,
    );
    await StepNotificationService.instance.cancelAll();
    expect(
        pending.values
            .where((p) => (p['payload'] as String).startsWith('sequence:'))
            .length,
        3);
  });

  test('sign-out cancels repeats; signing back in restores stored schedules',
      () async {
    await save('morning');
    await service.synchronizeAccount(null);
    expect(pending, isEmpty);
    await service.synchronizeAccount('bob');
    expect(pending, isEmpty);
    await service.synchronizeAccount('alice');
    expect(pending.length, 3);
    await service.remove('alice', 'morning');
    expect(pending, isEmpty);
    expect(await service.getForSet('alice', 'morning'), isNull);
  });

  test('enabled schedules reject an empty weekday selection', () async {
    await expectLater(save('morning', days: []), throwsArgumentError);
    expect(pending, isEmpty);
  });
}
