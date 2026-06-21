import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing watch sessions in Firestore
class WatchSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection name in Firestore
  static const String _collectionName = 'watch_sessions';

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if error is due to offline/network issues
  bool _isOfflineError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('offline') ||
        errorString.contains('unavailable') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }

  /// Start a new watch session
  Future<void> startSession({
    required String setName,
    required int currentIndex,
    required int totalSteps,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] User not authenticated, skipping session start');
      }
      return;
    }

    try {
      await _firestore.collection(_collectionName).doc(userId).set({
        'isActive': true,
        'setName': setName,
        'currentIndex': currentIndex,
        'totalSteps': totalSteps,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] Session started: $setName (index: $currentIndex, total: $totalSteps)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] Firestore error starting session: $e');
      }
      if (_isOfflineError(e)) {
        return; // Silently fail for offline issues
      }
      rethrow;
    }
  }

  /// Update the current step index of the watch session
  Future<void> updateIndex(int index) async {
    final userId = _currentUserId;
    if (userId == null) {
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] User not authenticated, skipping index update');
      }
      return;
    }

    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'currentIndex': index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Session updated: index=$index');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Firestore error updating index: $e');
      }
      if (_isOfflineError(e)) {
        return; // Silently fail for offline issues
      }
      rethrow;
    }
  }

  /// End the watch session
  Future<void> endSession() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] User not authenticated, skipping session end');
      }
      return;
    }

    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Session ended');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Firestore error ending session: $e');
      }
      if (_isOfflineError(e)) {
        return; // Silently fail for offline issues
      }
      rethrow;
    }
  }
}
