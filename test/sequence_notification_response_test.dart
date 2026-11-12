import 'dart:async';
import 'package:caregiver/services/step_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cold-start and warm taps retain the matching routine; step taps do not',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    const morning = 'sequence:{"userId":"alice","setId":"morning"}';
    const evening = 'sequence:{"userId":"alice","setId":"evening"}';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'), (_) async => 'Asia/Karachi');
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'getNotificationAppLaunchDetails') {
        return {
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationId': 100000,
            'notificationResponseType': 0,
            'payload': morning,
          },
        };
      }
      return null;
    });
    final service = StepNotificationService.instance;
    expect(await service.ensureInitialized(), isTrue);
    expect(service.pendingSequenceReminder.value, morning);
    service.pendingSequenceReminder.value = null;

    Future<void> tap(String payload) async {
      final response = Completer<void>();
      ServicesBinding.instance.channelBuffers.push(
          channel.name,
          const StandardMethodCodec()
              .encodeMethodCall(MethodCall('didReceiveNotificationResponse', {
            'notificationId': 100007,
            'notificationResponseType': 0,
            'payload': payload,
          })),
          (_) => response.complete());
      await response.future;
    }

    await tap(evening);
    expect(service.pendingSequenceReminder.value, evening);
    service.pendingSequenceReminder.value = null;
    await tap('2026-11-16T08:00:00.000+0500');
    expect(service.pendingSequenceReminder.value, isNull);
  });
}
