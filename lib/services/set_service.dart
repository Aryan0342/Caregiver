import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import 'custom_pictogram_service.dart';

/// Service for managing pictogram sets in Firestore
class SetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CustomPictogramService _pictogramService = CustomPictogramService();

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
  /// When offline, Firestore will automatically queue the write and sync when online
  Future<String?> createSet(PictogramSet set) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Firestore's .add() returns immediately with a document reference
      // even when offline. The write is automatically queued and will sync when online.
      // No timeout needed - Firestore handles offline writes gracefully with persistence enabled.
      final docRef = _firestore.collection(_collectionName).doc();

      // Set the document data (this queues the write when offline)
      await docRef.set(set.toJson());

      // Track usage of pictograms (increment usage count)
      _trackPictogramUsage(set.pictograms);

      // Return the document ID (generated client-side, works offline)
      return docRef.id;
    } catch (e) {
      if (_isOfflineError(e)) {
        // When offline, Firestore should still queue the write
        // But if we get an error, it might be a permission issue
        // Try to create with a generated ID anyway
        try {
          final docRef = _firestore.collection(_collectionName).doc();
          // Use setOptions to ensure it's queued
          await docRef.set(set.toJson(), SetOptions(merge: false));
          return docRef.id;
        } catch (cacheError) {
          // If both attempts fail, throw offline message
          throw Exception(
            'Offline: Wijzigingen worden opgeslagen zodra u weer online bent',
          );
        }
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
      // Get old set to compare pictograms
      final oldSetDoc = await _firestore
          .collection(_collectionName)
          .doc(set.id)
          .get();
      final oldPictograms = oldSetDoc.exists
          ? (oldSetDoc.data()?['pictograms'] as List<dynamic>?)
                    ?.map((p) => Pictogram.fromJson(p as Map<String, dynamic>))
                    .toList() ??
                []
          : [];

      await _firestore.collection(_collectionName).doc(set.id).update({
        'name': set.name,
        'pictograms': set.pictograms.map((p) => p.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Track usage of newly added pictograms (compare old vs new)
      final oldIds = oldPictograms.map((p) => p.id).toSet();
      final newPictograms = set.pictograms
          .where((p) => !oldIds.contains(p.id))
          .toList();
      if (newPictograms.isNotEmpty) {
        _trackPictogramUsage(newPictograms);
      }
    } catch (e) {
      if (_isOfflineError(e)) {
        throw Exception(
          'Offline: Wijzigingen worden opgeslagen zodra u weer online bent',
        );
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
        throw Exception(
          'Offline: Verwijdering wordt uitgevoerd zodra u weer online bent',
        );
      }
      throw Exception('Failed to delete set: $e');
    }
  }

  /// Delete all pictogram sets for the current user.
  /// Used when deleting the account.
  Future<void> deleteAllSetsForCurrentUser() async {
    if (_currentUserId == null) return;
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _currentUserId)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete user sets: $e');
    }
  }

  /// All pictograms are now custom and stored with keywords, so no enhancement needed
  Future<PictogramSet> _enhanceSetPictograms(PictogramSet set) async {
    // No enhancement needed - all pictograms are custom with proper keywords
    return set;
  }

  /// Get all sets for the current user
  /// Uses a fallback query without orderBy if the index is still building
  /// Includes cached data when offline
  Stream<List<PictogramSet>> getUserSets() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    // Use the query without orderBy and sort in memory
    // This works immediately while the index is building
    // Once the index is ready, you can switch back to orderBy for better performance
    // snapshots() automatically includes cached data when offline (if persistence is enabled)
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final sets = snapshot.docs
                .map((doc) => PictogramSet.fromJson(doc.id, doc.data()))
                .toList();

            // Enhance pictograms with proper keywords if needed
            final enhancedSets = await Future.wait(
              sets.map((set) => _enhanceSetPictograms(set)),
            );

            // Sort in memory by createdAt descending (newest first)
            enhancedSets.sort((a, b) {
              return b.createdAt.compareTo(a.createdAt);
            });
            return enhancedSets;
          } catch (e) {
            // If parsing fails, return empty list
            return <PictogramSet>[];
          }
        })
        .handleError((error) {
          // When offline, Firestore will return cached data
          if (_isOfflineError(error)) {
            return <PictogramSet>[];
          }
          // Re-throw other errors
          throw error;
        });
  }

  /// Get all sets (for client mode - no user filter)
  /// Returns all pictogram sets from Firestore
  Stream<List<PictogramSet>> getAllSets() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final sets = snapshot.docs
                .map((doc) => PictogramSet.fromJson(doc.id, doc.data()))
                .toList();

            // Enhance pictograms with proper keywords if needed
            final enhancedSets = await Future.wait(
              sets.map((set) => _enhanceSetPictograms(set)),
            );

            // Sort in memory by createdAt descending (newest first)
            enhancedSets.sort((a, b) {
              return b.createdAt.compareTo(a.createdAt);
            });
            return enhancedSets;
          } catch (e) {
            // If parsing fails, return empty list
            return <PictogramSet>[];
          }
        })
        .handleError((error) {
          // When offline, Firestore will return cached data
          if (_isOfflineError(error)) {
            return <PictogramSet>[];
          }
          // Re-throw other errors
          throw error;
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

  /// Track pictogram usage by incrementing usage count in Firestore.
  ///
  /// This is called when pictograms are added to sets to track popularity.
  /// Usage tracking happens asynchronously and won't block set creation.
  void _trackPictogramUsage(List<Pictogram> pictograms) {
    if (pictograms.isEmpty) return;

    // Run asynchronously so it doesn't block set creation
    _pictogramService
        .getPictogramDocumentIds(pictograms)
        .then((docIdMap) {
          final docIds = docIdMap.values.toSet().toList();
          if (docIds.isNotEmpty) {
            _pictogramService.incrementUsageCountBatch(docIds);
          }
        })
        .catchError((e) {
          // Log error but don't throw - usage tracking shouldn't break the app
          // Error is already logged in incrementUsageCountBatch
        });
  }
}
