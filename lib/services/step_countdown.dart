import 'dart:async';
import 'package:flutter/foundation.dart';

/// Counts the current step once. The next step starts only when the session
/// actually displays it, so background time never skips unseen pictograms.
class StepCountdown extends ChangeNotifier {
  StepCountdown({required this.onElapsed, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final VoidCallback onElapsed;
  final DateTime Function() _now;
  Timer? _ticker;
  DateTime? _deadline;
  Duration? _duration;
  Duration _remaining = Duration.zero;
  bool _autoAdvance = false;
  bool _handled = false;
  bool _paused = false;
  bool _userPaused = false;
  bool _foreground = true;

  Duration? get duration => _duration;
  bool get isUserPaused => _userPaused;
  bool get isPaused => _paused || _userPaused;
  int get remainingSeconds => (_remaining.inMilliseconds / 1000).ceil();
  bool get hasElapsed => _duration != null && _remaining == Duration.zero;
  double get progress => _duration == null
      ? 0
      : (1 - _remaining.inMilliseconds / _duration!.inMilliseconds)
          .clamp(0.0, 1.0);

  void setAutoAdvance(bool value) {
    _autoAdvance = value;
    _tick();
  }

  void start(Duration? duration, {bool? autoAdvance}) {
    _ticker?.cancel();
    if (autoAdvance != null) _autoAdvance = autoAdvance;
    _userPaused = false;
    _duration = duration != null && duration > Duration.zero ? duration : null;
    _remaining = _duration ?? Duration.zero;
    _deadline = _duration == null ? null : _now().add(_remaining);
    _handled = false;
    notifyListeners();
    _run();
  }

  void stop() => start(null);

  /// Modal dialogs freeze the countdown until the step is visible again.
  void pause() {
    _changePause(routePaused: true);
  }

  void resume() {
    _changePause(routePaused: false);
  }

  void toggleUserPause() => _changePause(userPaused: !_userPaused);

  void _changePause({bool? routePaused, bool? userPaused}) {
    final wasPaused = isPaused;
    _paused = routePaused ?? _paused;
    _userPaused = userPaused ?? _userPaused;
    if (!wasPaused && isPaused) {
      _ticker?.cancel();
      if (_deadline != null) {
        _remaining = _positive(_deadline!.difference(_now()));
      }
    } else if (wasPaused && !isPaused) {
      if (_duration != null) _deadline = _now().add(_remaining);
      _run();
    }
    notifyListeners();
  }

  /// Preserve the deadline while backgrounded, but advance only on return.
  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground) {
      _ticker?.cancel();
    } else {
      _run();
    }
  }

  Duration _positive(Duration value) =>
      value.isNegative ? Duration.zero : value;

  void _run() {
    _ticker?.cancel();
    if (_duration == null || isPaused || !_foreground || _handled) return;
    if (_remaining > Duration.zero) {
      _ticker =
          Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    }
    _tick();
  }

  void _tick() {
    if (_duration == null || isPaused || !_foreground || _handled) return;
    _remaining = _positive(_deadline!.difference(_now()));
    notifyListeners();
    if (_remaining == Duration.zero) {
      _ticker?.cancel();
      if (_autoAdvance) {
        _handled = true;
        onElapsed();
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
