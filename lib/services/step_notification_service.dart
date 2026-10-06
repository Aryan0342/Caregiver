import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/pictogram_model.dart';

/// Schedules local notifications for the planned times of pictogram steps
/// ("time for your next pictogram").
class StepNotificationService {
  StepNotificationService._();

  static final StepNotificationService instance = StepNotificationService._();

  static const String _channelId = 'step_reminders';
  static const int _idBase = 4200;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _hasScheduled = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    if (!_isSupported) return false;
    try {
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[StepNotificationService] Initialization failed: $e');
    }
    return _initialized;
  }

  /// Asks the user for permission to show notifications. Returns whether
  /// notifications are allowed.
  Future<bool> requestPermission() async {
    if (!await _ensureInitialized()) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final allowed = await android.requestNotificationsPermission() ?? false;
        // Without the "Alarms & reminders" permission Android delivers
        // scheduled notifications late (or batches them), so ask for it too.
        if (allowed &&
            !(await android.canScheduleExactNotifications() ?? true)) {
          await android.requestExactAlarmsPermission();
        }
        return allowed;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
    } catch (e) {
      debugPrint('[StepNotificationService] Permission request failed: $e');
    }
    return false;
  }

  /// Replaces any scheduled step notifications with one for each step after
  /// [currentIndex] that has a planned time later today and notifications
  /// enabled. [titleFor] builds the (localized) notification title.
  Future<void> scheduleForSteps({
    required List<Pictogram> steps,
    required int currentIndex,
    required String setName,
    required String channelName,
    required String Function(Pictogram step) titleFor,
  }) async {
    final hasNotifyingStep =
        steps.any((step) => step.notify && step.scheduledMinutes != null);
    if (!hasNotifyingStep && !_hasScheduled) return;
    if (!await _ensureInitialized()) return;

    try {
      await _cancelUpcoming();
      if (!hasNotifyingStep) return;

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canScheduleExact =
          await android?.canScheduleExactNotifications() ?? true;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      final now = tz.TZDateTime.now(tz.local);
      for (var i = currentIndex + 1; i < steps.length; i++) {
        final step = steps[i];
        final minutes = step.scheduledMinutes;
        if (!step.notify || minutes == null) continue;
        final scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
            now.day, minutes ~/ 60, minutes % 60);
        if (!scheduledDate.isAfter(now)) continue;

        await _plugin.zonedSchedule(
          id: _idBase + i,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          // Exact alarms need a permission that is off by default on newer
          // Android versions; fall back to a (slightly delayed) inexact one.
          androidScheduleMode: canScheduleExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: titleFor(step),
          body: setName,
          // The due time lets later reschedules keep notifications that are
          // already due but not yet delivered by the system.
          payload: scheduledDate.toIso8601String(),
        );
        _hasScheduled = true;
      }
    } catch (e) {
      debugPrint('[StepNotificationService] Scheduling failed: $e');
    }
  }

  /// Cancels the step notifications that are not due yet. Notifications whose
  /// time has passed are kept: Android may still be about to deliver them.
  Future<void> cancelAll() async {
    if (!_hasScheduled && !_initialized) return;
    if (!await _ensureInitialized()) return;
    await _cancelUpcoming();
  }

  Future<void> _cancelUpcoming() async {
    try {
      final now = DateTime.now();
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id < _idBase) continue;
        final dueAt = DateTime.tryParse(request.payload ?? '');
        if (dueAt == null || dueAt.isAfter(now)) {
          await _plugin.cancel(id: request.id);
        }
      }
      _hasScheduled = false;
    } catch (e) {
      debugPrint('[StepNotificationService] Cancel failed: $e');
    }
  }
}
