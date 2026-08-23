import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pictogram_model.dart';
import '../models/watch_session_snapshot.dart';

/// Service for managing watch sessions in Firestore
class WatchSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const MethodChannel _channel = MethodChannel('com.jedaginbeeld.wear');

  VoidCallback? _onNextCallback;
  VoidCallback? _onPrevCallback;
  void Function(bool isReachable)? _onReachabilityChanged;
  bool _handlerRegistered = false;
  StreamSubscription? _firestoreSubscription;

  WatchSessionSnapshot? _watchState;
  String? _lastNavigationCommandId;

  static const String _cloudinaryTransform = '/upload/w_200,h_200,c_fit/';
  static const String _collectionName = 'watch_sessions';

  String? get _currentUserId => _auth.currentUser?.uid;

  Map<String, dynamic>? _watchSnapshot(String userId, String action) {
    return _watchState?.toMap(userId: userId, action: action);
  }

  void _sendWatchSnapshot(String userId, String action) {
    final snapshot = _watchSnapshot(userId, action);
    if (snapshot != null) {
      unawaited(_sendViaDataLayer(snapshot));
    }
  }

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

  /// Check whether a paired Apple Watch has the companion app installed.
  /// On Android this channel call will simply throw/fail (no native handler
  /// for this method exists there), so it returns false safely.
  Future<bool> isWatchAppAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWatchAppInstalled');
      return result ?? false;
    } catch (_) {
      return false;
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

      _watchState = WatchSessionSnapshot(
        sessionId: '${userId}_${DateTime.now().microsecondsSinceEpoch}',
        revision: 1,
        isActive: true,
        setName: setName,
        currentIndex: currentIndex,
        totalSteps: totalSteps,
        pictograms: transformedPictograms,
      );

      // Phone-to-watch sync is local and should still work if Firestore is
      // temporarily unavailable.
      _sendWatchSnapshot(userId, 'START');

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
      final watchState = _watchState;
      if (watchState != null) {
        _watchState = watchState.copyWith(
          currentIndex: index,
          revision: watchState.revision + 1,
        );
      }

      _sendWatchSnapshot(userId, 'INDEX_CHANGE');

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
      final watchState = _watchState;
      if (watchState != null) {
        _watchState = watchState.copyWith(
          isActive: false,
          revision: watchState.revision + 1,
        );
      }

      _sendWatchSnapshot(userId, 'END');

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
        return;
      }
      rethrow;
    }
  }

  void startListeningToWatchNavigation({
    required VoidCallback onNext,
    required VoidCallback onPrev,
  }) {
    if (kDebugMode) {
      debugPrint(
          '[WatchSessionService] startListeningToWatchNavigation called');
    }
    _onNextCallback = onNext;
    _onPrevCallback = onPrev;

    _ensureHandlerRegistered();
    unawaited(_consumePendingNavigation());
  }

  void stopListeningToWatchNavigation() {
    _onNextCallback = null;
    _onPrevCallback = null;
  }

  /// Listens for connectivity changes to a paired Apple Watch. No-op on
  /// Android since no native side ever invokes 'onReachabilityChanged' there.
  void startListeningToReachability({
    required void Function(bool isReachable) onChanged,
  }) {
    _onReachabilityChanged = onChanged;
    _ensureHandlerRegistered();
  }

  void stopListeningToReachability() {
    _onReachabilityChanged = null;
  }

  void _ensureHandlerRegistered() {
    if (_handlerRegistered) return;
    _handlerRegistered = true;
    if (kDebugMode) {
      debugPrint('[WatchSessionService] Registering MethodChannel handler');
    }
    _channel.setMethodCallHandler((call) async {
      if (kDebugMode) {
        debugPrint(
            '[WatchSessionService] Method call received: ${call.method}, arguments: ${call.arguments}');
      }
      if (call.method == 'onWatchNavigation') {
        final arguments = Map<String, dynamic>.from(call.arguments as Map);
        _handleWatchNavigation(arguments);
        // Clear the native durable copy after the live command was handled.
        unawaited(_clearPendingNavigation());
      } else if (call.method == 'onReachabilityChanged') {
        final isReachable = call.arguments['isReachable'] as bool? ?? false;
        if (kDebugMode) {
          debugPrint(
              '[WatchSessionService] Reachability changed: $isReachable');
        }
        _onReachabilityChanged?.call(isReachable);
      }
    });
  }

  Future<void> _consumePendingNavigation() async {
    try {
      final pending = await _channel.invokeMapMethod<String, dynamic>(
        'getPendingWatchNavigation',
      );
      if (pending != null) {
        _handleWatchNavigation(pending);
      }
    } catch (_) {
      // Android has no pending-navigation method; its Data Layer handles this.
    }
  }

  Future<void> _clearPendingNavigation() async {
    try {
      await _channel.invokeMethod('getPendingWatchNavigation');
    } catch (_) {
      // Android does not implement this iOS-only durability method.
    }
  }

  void _handleWatchNavigation(Map<String, dynamic> arguments) {
    final commandId = arguments['commandId'] as String?;
    if (commandId != null && commandId == _lastNavigationCommandId) {
      return;
    }
    _lastNavigationCommandId = commandId;

    final incomingSessionId = arguments['sessionId'] as String?;
    if (incomingSessionId != null &&
        incomingSessionId != _watchState?.sessionId) {
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Ignoring command for old session');
      }
      return;
    }

    final action = arguments['action'] as String? ?? '';
    if (kDebugMode) {
      debugPrint('[WatchSessionService] Action: $action');
    }
    if (action == 'next') {
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Calling _onNextCallback');
      }
      _onNextCallback?.call();
    } else if (action == 'prev') {
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Calling _onPrevCallback');
      }
      _onPrevCallback?.call();
    }
  }

  void startListeningToFirestoreIndexChanges({
    required void Function(int index) onIndexChanged,
  }) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestoreSubscription?.cancel();
    _firestoreSubscription = _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;
      final index = data['currentIndex'] as int?;
      if (index == null) return;
      if (kDebugMode) {
        debugPrint('[WatchSessionService] Firestore index changed: $index');
      }
      onIndexChanged(index);
    });
  }

  void stopListeningToFirestoreIndexChanges() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }
}
