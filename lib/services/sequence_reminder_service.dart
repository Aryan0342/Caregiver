import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/sequence_reminder.dart';
import 'step_notification_service.dart';

class SequenceReminderService {
  SequenceReminderService._();
  static final instance = SequenceReminderService._();
  static const _storagePrefix = 'sequence_reminders_';
  static const _nextIdKey = 'sequence_reminder_next_id';
  final _notifications = StepNotificationService.instance;
  Future<void> _operations = Future.value();
  String? _activeAccount;
  bool _accountKnown = false;

  // Serialize changes so a sign-out cannot race a save or startup reschedule.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operations.then((_) => operation());
    _operations =
        result.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return result;
  }

  Future<List<SequenceReminder>> _read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((item) =>
            SequenceReminder.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> _write(String userId, List<SequenceReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString('$_storagePrefix$userId',
        jsonEncode(reminders.map((r) => r.toJson()).toList()));
    if (!saved) throw StateError('Could not save reminders');
  }

  Future<SequenceReminder?> getForSet(String userId, String setId) async {
    await _operations;
    for (final reminder in await _read(userId)) {
      if (reminder.setId == setId) return reminder;
    }
    return null;
  }

  Future<void> save({
    required String userId,
    required String setId,
    required String setName,
    required int hour,
    required int minute,
    required List<int> weekdays,
    required bool enabled,
    required String languageCode,
  }) =>
      _enqueue(() async {
        if (_accountKnown && _activeAccount != userId) {
          throw StateError('The signed-in account has changed');
        }
        final days = weekdays.toSet().toList()..sort();
        if (hour < 0 ||
            hour > 23 ||
            minute < 0 ||
            minute > 59 ||
            days.any((d) => d < 1 || d > 7) ||
            (enabled && days.isEmpty)) {
          throw ArgumentError('Invalid reminder schedule');
        }
        if (!await _notifications.ensureInitialized()) {
          throw StateError('Notifications are unavailable');
        }
        final reminders = await _read(userId);
        final index = reminders.indexWhere((r) => r.setId == setId);
        final old = index < 0 ? null : reminders[index];
        final prefs = await SharedPreferences.getInstance();
        final baseId =
            old?.notificationBaseId ?? prefs.getInt(_nextIdKey) ?? 100000;
        if (old == null) await prefs.setInt(_nextIdKey, baseId + 7);
        final reminder = SequenceReminder(
          userId: userId,
          setId: setId,
          setName: setName,
          hour: hour,
          minute: minute,
          weekdays: days,
          notificationBaseId: baseId,
          enabled: enabled,
          languageCode: languageCode,
        );
        // iOS only keeps 64 pending requests. Reserve 20 for a full sequence's
        // step reminders (the sequence picker's maximum length).
        if (enabled && defaultTargetPlatform == TargetPlatform.iOS) {
          final pending =
              await _notifications.plugin.pendingNotificationRequests();
          final otherCount =
              pending.where((p) => p.id < baseId || p.id >= baseId + 7).length;
          if (otherCount + days.length > 44) {
            throw StateError(languageCode == 'nl'
                ? 'Te veel herinneringen. Schakel eerst een andere herinnering uit.'
                : 'Too many reminders. Disable another reminder first.');
          }
        }
        await _cancel(reminder);
        try {
          if (enabled) await _schedule(reminder);
          if (index < 0) {
            reminders.add(reminder);
          } else {
            reminders[index] = reminder;
          }
          await _write(userId, reminders);
        } catch (_) {
          await _cancel(reminder);
          if (old != null && old.enabled) await _schedule(old);
          rethrow;
        }
      });

  Future<void> remove(String userId, String setId) => _enqueue(() async {
        final reminders = await _read(userId);
        for (final reminder in reminders.where((r) => r.setId == setId)) {
          if (await _notifications.ensureInitialized()) await _cancel(reminder);
        }
        reminders.removeWhere((r) => r.setId == setId);
        await _write(userId, reminders);
      });

  /// Cancel the previous account's OS notifications and restore this account's.
  /// The OS repeats weekly and restores alarms after Android reboots.
  Future<void> synchronizeAccount(String? userId) {
    _activeAccount = userId;
    _accountKnown = true;
    return _enqueue(() async {
      if (_activeAccount != userId) return;
      if (!await _notifications.ensureInitialized()) return;
      final pending = await _notifications.plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.payload?.startsWith('sequence:') ?? false) {
          await _notifications.plugin.cancel(id: request.id);
        }
      }
      if (userId == null) return;
      for (final reminder in await _read(userId)) {
        if (reminder.enabled) await _schedule(reminder);
      }
    });
  }

  Future<void> _cancel(SequenceReminder reminder) async {
    for (var day = 0; day < 7; day++) {
      await _notifications.plugin.cancel(id: reminder.notificationBaseId + day);
    }
  }

  Future<void> _schedule(SequenceReminder reminder) async {
    final android = _notifications.plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? true;
    final dutch = reminder.languageCode == 'nl';
    final now = tz.TZDateTime.now(tz.local);
    for (final day in reminder.weekdays) {
      await _notifications.plugin.zonedSchedule(
        id: reminder.notificationBaseId + day - 1,
        title: dutch ? 'Tijd voor uw routine' : 'Time for your routine',
        body: dutch
            ? 'Wilt u "${reminder.setName}" starten?'
            : 'Would you like to start "${reminder.setName}"?',
        scheduledDate: reminder.nextOccurrence(now, day),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'sequence_reminders',
            dutch ? 'Routineherinneringen' : 'Routine reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'sequence:${jsonEncode({
              'userId': reminder.userId,
              'setId': reminder.setId
            })}',
      );
    }
  }
}
