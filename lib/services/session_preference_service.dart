import 'package:shared_preferences/shared_preferences.dart';

/// Stores caregiver preferences for the client session screen.
class SessionPreferenceService {
  static const String _completionCheckmarkKey =
      'session_completion_checkmark_enabled';
  static const String _completionSoundKey = 'session_completion_sound_enabled';

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
}
