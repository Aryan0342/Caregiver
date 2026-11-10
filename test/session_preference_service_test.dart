import 'package:caregiver/services/session_preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('pictogram timers are available by default', () async {
    expect(await SessionPreferenceService().isPictogramTimerEnabled(), isTrue);
  });

  test(
      'timer on/off persists across routines without changing other preferences',
      () async {
    final preferences = SessionPreferenceService();
    await preferences.setCompletionSoundEnabled(false);
    await preferences.setPictogramTimerEnabled(false);
    final reopened = SessionPreferenceService();
    expect(await reopened.isPictogramTimerEnabled(), isFalse);
    expect(await reopened.isCompletionSoundEnabled(), isFalse);
    await reopened.setPictogramTimerEnabled(true);
    expect(await SessionPreferenceService().isPictogramTimerEnabled(), isTrue);
  });
}
