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
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PictogramSet.fromJson(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get a single set by ID
  Future<PictogramSet?> getSet(String setId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(setId)
          .get();

      if (doc.exists) {
        return PictogramSet.fromJson(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get set: $e');
    }
  }
}
