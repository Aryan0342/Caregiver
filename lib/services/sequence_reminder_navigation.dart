import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';
import '../screens/client_mode_session_screen.dart';
import 'set_service.dart';
import 'step_notification_service.dart';

/// Retain cold-start taps until the normal sign-in, PIN and setup flow has
/// reached home. Never route directly around those screens from a notification.
class SequenceReminderNavigation extends NavigatorObserver {
  SequenceReminderNavigation(this.navigatorKey) {
    StepNotificationService.instance.pendingSequenceReminder
        .addListener(_changed);
  }

  final GlobalKey<NavigatorState> navigatorKey;
  final List<Route<dynamic>> _routes = [];
  bool _opening = false;
  bool _disposed = false;

  void dispose() {
    _disposed = true;
    StepNotificationService.instance.pendingSequenceReminder
        .removeListener(_changed);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    _changed();
  }

  void _changed() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool get _ready =>
      !_disposed &&
      _routes.any((r) => r.settings.name == AppRoutes.home) &&
      FirebaseAuth.instance.currentUser?.emailVerified == true;

  Future<void> _openPending() async {
    if (!_ready || _opening) return;
    final pending = StepNotificationService.instance.pendingSequenceReminder;
    final payload = pending.value;
    final navigator = navigatorKey.currentState;
    if (payload == null || navigator == null) return;
    // Wait for open dialogs and PIN prompts to close before showing a prompt.
    if (_routes.lastOrNull is PopupRoute) return;
    _opening = true;
    try {
      final data = jsonDecode(payload.substring('sequence:'.length)) as Map;
      final userId = data['userId'] as String;
      final setId = data['setId'] as String;
      pending.value = null;
      if (FirebaseAuth.instance.currentUser?.uid != userId) return;
      final set = await SetService().getSet(setId);
      if (!_ready ||
          !navigator.mounted ||
          FirebaseAuth.instance.currentUser?.uid != userId) {
        return;
      }
      final strings = LanguageProvider.localizationsOf(navigator.context);
      if (set == null || set.userId != userId || set.pictograms.isEmpty) {
        ScaffoldMessenger.of(navigator.context)
            .showSnackBar(SnackBar(content: Text(strings.reminderUnavailable)));
        return;
      }
      final start = await showDialog<bool>(
        context: navigator.context,
        builder: (context) => AlertDialog(
          title: Text(strings.routineReminder),
          content: Text(strings.routineStartPrompt(set.name)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(strings.reminderNotNow)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings.startSequence)),
          ],
        ),
      );
      if (start == true &&
          _ready &&
          navigator.mounted &&
          FirebaseAuth.instance.currentUser?.uid == userId) {
        navigator.push(MaterialPageRoute(
            builder: (_) =>
                ClientModeSessionScreen(set: set, startFromBeginning: true)));
      }
    } catch (_) {
      pending.value = null;
      if (navigator.mounted && _ready) {
        final strings = LanguageProvider.localizationsOf(navigator.context);
        ScaffoldMessenger.of(navigator.context)
            .showSnackBar(SnackBar(content: Text(strings.reminderUnavailable)));
      }
    } finally {
      _opening = false;
      if (pending.value != null && pending.value != payload) _changed();
    }
  }
}
