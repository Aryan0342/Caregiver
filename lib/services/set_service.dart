import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/set_model.dart';

/// Service for managing pictogram sets in Firestore
class SetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection name in Firestore
  static const String _collectionName = 'pictogram_sets';

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

  /// Create a new pictogram set
  Future<String?> createSet(PictogramSet set) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(set.toJson());
      return docRef.id;
    } catch (e) {
      if (_isOfflineError(e)) {
        // When offline, Firestore will queue the write
        // Return a temporary ID - the real ID will be assigned when online
        throw Exception('Offline: Wijzigingen worden opgeslagen zodra u weer online bent');
      }
      throw Exception('Failed to create set: $e');
    }
  }

  /// Update an existing pictogram set
  Future<void> updateSet(PictogramSet set) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(_collectionName)
          .doc(set.id)
          .update({
        'name': set.name,
        'pictograms': set.pictograms.map((p) => p.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (_isOfflineError(e)) {
        throw Exception('Offline: Wijzigingen worden opgeslagen zodra u weer online bent');
      }
      throw Exception('Failed to update set: $e');
    }
  }

  /// Delete a pictogram set
  Future<void> deleteSet(String setId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection(_collectionName).doc(setId).delete();
    } catch (e) {
      if (_isOfflineError(e)) {
        throw Exception('Offline: Verwijdering wordt uitgevoerd zodra u weer online bent');
      }
      throw Exception('Failed to delete set: $e');
    }
  }

  /// Get all sets for the current user
  Stream<List<PictogramSet>> getUserSets() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      // When offline, Firestore will return cached data
      // If there's an error, return empty list instead of crashing
      if (_isOfflineError(error)) {
        return <PictogramSet>[];
      }
      throw error;
    }).map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => PictogramSet.fromJson(doc.id, doc.data()))
            .toList();
      } catch (e) {
        // If parsing fails, return empty list
        return <PictogramSet>[];
      }
    });
  }

  /// Get a single set by ID
  Future<PictogramSet?> getSet(String setId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(setId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        return PictogramSet.fromJson(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      if (_isOfflineError(e)) {
        // Try to get from cache
        try {
          final doc = await _firestore
              .collection(_collectionName)
              .doc(setId)
              .get(const GetOptions(source: Source.cache));
          if (doc.exists) {
            return PictogramSet.fromJson(doc.id, doc.data()!);
          }
        } catch (_) {
          // Cache also failed, return null
        }
        throw Exception('Offline: Gegevens niet beschikbaar');
      }
      throw Exception('Failed to get set: $e');
    }
  }
}
