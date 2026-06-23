import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pictogram_model.dart';

/// Service for managing watch sessions in Firestore
class WatchSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const MethodChannel _channel = MethodChannel('com.jedaginbeeld.wear');

  static const String _cloudinaryTransform = '/upload/w_200,h_200,c_fit/';
  static const String _collectionName = 'watch_sessions';

  String? get _currentUserId => _auth.currentUser?.uid;

  bool _isOfflineError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('offline') ||
        errorString.contains('unavailable') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }

  String _transformCloudinaryUrl(String imageUrl) {
    if (imageUrl.isEmpty) {
      return imageUrl;
    }

    if (imageUrl.contains(_cloudinaryTransform)) {
      return imageUrl;
    }

    const uploadSegment = '/upload/';
    if (imageUrl.contains(uploadSegment)) {
      return imageUrl.replaceFirst(uploadSegment, _cloudinaryTransform);
    }

    return imageUrl;
  }

  Future<void> _sendViaDataLayer(Map<String, dynamic> data) async {
    try {
      await _channel.invokeMethod('sendToWear', {'data': data});
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Data sent to DataLayer: $data');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] Failed to send data to DataLayer: $e');
      }
    }
  }

  Future<void> startSession({
    required String setName,
    required int currentIndex,
    required int totalSteps,
    required List<Pictogram> pictograms,
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
      final transformedPictograms = <Map<String, dynamic>>[];
      for (int i = 0; i < pictograms.length; i++) {
        final pictogram = pictograms[i];
        transformedPictograms.add({
          'index': i,
          'keyword': pictogram.keyword,
          'imageUrl': _transformCloudinaryUrl(pictogram.imageUrl),
        });
      }

      await _firestore.collection(_collectionName).doc(userId).set({
        'isActive': true,
        'setName': setName,
        'currentIndex': currentIndex,
        'totalSteps': totalSteps,
        'pictograms': transformedPictograms,
        'customToken': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] Session started: $setName (index: $currentIndex, total: $totalSteps)');
      }

      _sendViaDataLayer({
        'action': 'START',
        'userId': userId,
        'currentIndex': currentIndex,
        'totalSteps': totalSteps,
        'setName': setName,
        'pictograms': transformedPictograms,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] Firestore error starting session: $e');
      }
      if (_isOfflineError(e)) {
        return;
      }
      rethrow;
    }
  }

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

      _sendViaDataLayer({
        'action': 'INDEX_CHANGE',
        'currentIndex': index,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Firestore error updating index: $e');
      }
      if (_isOfflineError(e)) {
        return;
      }
      rethrow;
    }
  }

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

      _sendViaDataLayer({
        'action': 'END',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Firestore error ending session: $e');
      }
      if (_isOfflineError(e)) {
        return;
      }
      rethrow;
    }
  }

  void startListeningToWatchNavigation({
    required VoidCallback onNext,
    required VoidCallback onPrev,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWatchNavigation') {
        final action = call.arguments['action'] as String;
        if (action == 'next') {
          onNext();
        } else if (action == 'prev') {
          onPrev();
        }
      }
    });
  }

  void stopListeningToWatchNavigation() {
    _channel.setMethodCallHandler(null);
  }
}
