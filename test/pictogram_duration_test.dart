import 'package:caregiver/models/pictogram_model.dart';
import 'package:caregiver/models/set_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const picto =
      Pictogram(id: 1, keyword: 'Brush teeth', category: 'Care', imageUrl: '');
  test('existing pictograms without duration remain untimed', () {
    expect(Pictogram.fromJson(picto.toJson()).durationSeconds, isNull);
  });
  test('duration survives saved sequences, sharing data and other edits', () {
    final timed = picto.copyWith(
        durationSeconds: 125, scheduledTime: '08:00', notify: true);
    final set = PictogramSet(
        id: 'routine',
        name: 'Morning',
        userId: 'alice',
        pictograms: [timed],
        createdAt: DateTime(2026));
    final restored =
        PictogramSet.fromJson('routine', set.toJson()).pictograms.single;
    expect(restored.durationSeconds, 125);
    expect(restored.copyWith(isNegated: true).durationSeconds, 125);
    final cleared = restored.copyWith(clearDuration: true);
    expect(cleared.durationSeconds, isNull);
    expect(cleared.scheduledTime, '08:00');
    expect(cleared.notify, isTrue);
  });
  test('invalid stored durations do not activate a countdown', () {
    for (final invalid in [0, -1, 86401, '5', 0.5]) {
      expect(
          Pictogram.fromJson({...picto.toJson(), 'durationSeconds': invalid})
              .durationSeconds,
          isNull);
    }
  });
  test('automatic completion is saved independently for each pictogram', () {
    final automatic =
        picto.copyWith(durationSeconds: 600, autoAdvanceAfterTimer: true);
    final manual = picto.copyWith(
        id: 2, durationSeconds: 120, autoAdvanceAfterTimer: false);
    expect(
        Pictogram.fromJson(automatic.toJson()).autoAdvanceAfterTimer, isTrue);
    expect(Pictogram.fromJson(manual.toJson()).autoAdvanceAfterTimer, isFalse);
    expect(manual.copyWith(keyword: 'Edited').autoAdvanceAfterTimer, isFalse);
    final legacy = picto.toJson()..['durationSeconds'] = 60;
    expect(Pictogram.fromJson(legacy).autoAdvanceAfterTimer, isTrue);
  });
}
