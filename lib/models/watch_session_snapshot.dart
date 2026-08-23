/// Immutable, platform-neutral state sent from the phone to a companion watch.
///
/// Every message is a complete snapshot because Apple Watch application
/// context keeps only the most recent pending value.
class WatchSessionSnapshot {
  const WatchSessionSnapshot({
    required this.sessionId,
    required this.revision,
    required this.isActive,
    required this.setName,
    required this.currentIndex,
    required this.totalSteps,
    required this.pictograms,
  });

  final String sessionId;
  final int revision;
  final bool isActive;
  final String setName;
  final int currentIndex;
  final int totalSteps;
  final List<Map<String, dynamic>> pictograms;

  WatchSessionSnapshot copyWith({
    int? revision,
    bool? isActive,
    int? currentIndex,
  }) {
    return WatchSessionSnapshot(
      sessionId: sessionId,
      revision: revision ?? this.revision,
      isActive: isActive ?? this.isActive,
      setName: setName,
      currentIndex: currentIndex ?? this.currentIndex,
      totalSteps: totalSteps,
      pictograms: pictograms,
    );
  }

  Map<String, dynamic> toMap({
    required String userId,
    required String action,
  }) {
    return {
      'action': action,
      'schemaVersion': 1,
      'sessionId': sessionId,
      'revision': revision,
      'isActive': isActive,
      'userId': userId,
      'setName': setName,
      'currentIndex': currentIndex,
      'totalSteps': totalSteps,
      'pictograms': pictograms,
    };
  }
}
