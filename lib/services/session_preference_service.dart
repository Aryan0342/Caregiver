import 'package:shared_preferences/shared_preferences.dart';

/// Stores caregiver preferences for the client session screen.
class SessionPreferenceService {
  static const String _completionCheckmarkKey =
      'session_completion_checkmark_enabled';
  static const String _completionSoundKey = 'session_completion_sound_enabled';
  static const String _previousPreviewCountKey =
      'session_previous_preview_count';
  static const String _upcomingPreviewCountKey =
      'session_upcoming_preview_count';

  /// Most done or upcoming pictos shown in the overview under the current
  /// pictogram.
  static const int maxPreviewCount = 10;
  static const int defaultPreviousPreviewCount = maxPreviewCount;
  static const int defaultUpcomingPreviewCount = 3;

  /// Whether a large check mark is shown after finishing a pictogram.
  /// Enabled by default.
  Future<bool> isCompletionCheckmarkEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_completionCheckmarkKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setCompletionCheckmarkEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completionCheckmarkKey, enabled);
    } catch (_) {
      // Ignore storage errors.
    }
  }

  /// Whether a sound is played after finishing a pictogram.
  /// Enabled by default.
  Future<bool> isCompletionSoundEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_completionSoundKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setCompletionSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completionSoundKey, enabled);
    } catch (_) {
      // Ignore storage errors.
    }
  }

  /// How many done pictos are shown in the session overview.
  Future<int> getPreviousPreviewCount() =>
      _getCount(_previousPreviewCountKey, defaultPreviousPreviewCount);

  Future<void> setPreviousPreviewCount(int count) =>
      _setCount(_previousPreviewCountKey, count);

  /// How many upcoming pictos are shown in the session overview.
  Future<int> getUpcomingPreviewCount() =>
      _getCount(_upcomingPreviewCountKey, defaultUpcomingPreviewCount);

  Future<void> setUpcomingPreviewCount(int count) =>
      _setCount(_upcomingPreviewCountKey, count);

  Future<int> _getCount(String key, int fallback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getInt(key) ?? fallback).clamp(0, maxPreviewCount);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _setCount(String key, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, count.clamp(0, maxPreviewCount));
    } catch (_) {
      // Ignore storage errors.
    }
  }
}
