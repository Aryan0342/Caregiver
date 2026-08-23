import 'package:caregiver/models/watch_session_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pictograms = <Map<String, dynamic>>[
    {'index': 0, 'keyword': 'Breakfast', 'imageUrl': 'https://img/1.png'},
    {'index': 1, 'keyword': 'School', 'imageUrl': 'https://img/2.png'},
  ];

  const initial = WatchSessionSnapshot(
    sessionId: 'user_123',
    revision: 1,
    isActive: true,
    setName: 'Morning routine',
    currentIndex: 0,
    totalSteps: 2,
    pictograms: pictograms,
  );

  test('start payload is a complete versioned snapshot', () {
    final payload = initial.toMap(userId: 'user', action: 'START');

    expect(payload, {
      'action': 'START',
      'schemaVersion': 1,
      'sessionId': 'user_123',
      'revision': 1,
      'isActive': true,
      'userId': 'user',
      'setName': 'Morning routine',
      'currentIndex': 0,
      'totalSteps': 2,
      'pictograms': pictograms,
    });
  });

  test('index update retains all routine data', () {
    final updated = initial.copyWith(currentIndex: 1, revision: 2);
    final payload = updated.toMap(userId: 'user', action: 'INDEX_CHANGE');

    expect(payload['currentIndex'], 1);
    expect(payload['revision'], 2);
    expect(payload['setName'], initial.setName);
    expect(payload['totalSteps'], initial.totalSteps);
    expect(payload['pictograms'], pictograms);
  });

  test('end payload remains complete and marks session inactive', () {
    final ended = initial.copyWith(isActive: false, revision: 3);
    final payload = ended.toMap(userId: 'user', action: 'END');

    expect(payload['isActive'], isFalse);
    expect(payload['revision'], 3);
    expect(payload['sessionId'], initial.sessionId);
    expect(payload['pictograms'], pictograms);
  });
}
