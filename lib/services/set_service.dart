import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../services/arasaac_service.dart';

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
          throw Exception('Offline: Wijzigingen worden opgeslagen zodra u weer online bent');
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

  /// Enhance pictograms in a set with proper keywords if they have "Pictogram {id}"
  /// Only enhances pictograms that need it (have "Pictogram {id}" as keyword)
  /// Skips enhancement when offline to avoid spamming API with failed requests
  Future<PictogramSet> _enhanceSetPictograms(PictogramSet set) async {
    // Check if any pictogram needs enhancement
    final needsEnhancement = set.pictograms.any((p) => 
      p.keyword.startsWith('Pictogram ') && p.id > 0
    );
    
    if (!needsEnhancement) {
      // No enhancement needed, return as-is
      return set;
    }
    
    final arasaacService = ArasaacService();
    final enhancedPictograms = <Pictogram>[];
    
    // Find first pictogram that needs enhancement to test connectivity
    final firstPictogramToEnhance = set.pictograms.firstWhere(
      (p) => p.keyword.startsWith('Pictogram ') && p.id > 0,
      orElse: () => set.pictograms.first,
    );
    
    // Test connectivity with first pictogram
    bool isOnline = false;
    try {
      final testEnhanced = await arasaacService.getPictogramById(firstPictogramToEnhance.id)
          .timeout(const Duration(seconds: 2));
      isOnline = testEnhanced != null;
    } catch (e) {
      // Network error or timeout - assume offline
      isOnline = false;
    }
    
    // If offline, return set as-is without enhancement
    if (!isOnline) {
      return set;
    }
    
    // Online - enhance all pictograms that need it (in parallel for better performance)
    final enhancementFutures = set.pictograms.map((pictogram) async {
      // If keyword is "Pictogram {id}", try to fetch proper keyword
      if (pictogram.keyword.startsWith('Pictogram ') && pictogram.id > 0) {
        try {
          final enhanced = await arasaacService.getPictogramById(pictogram.id);
          if (enhanced != null && enhanced.keyword.isNotEmpty && enhanced.keyword != 'Onbekend') {
            // Use enhanced keyword, keep other properties
            return pictogram.copyWith(
              keyword: enhanced.keyword,
              category: enhanced.category,
            );
          }
        } catch (e) {
          // Silently fail - use original pictogram
        }
      }
      // Keep original pictogram if enhancement failed or not needed
      return pictogram;
    });
    
    enhancedPictograms.addAll(await Future.wait(enhancementFutures));
    
    return set.copyWith(pictograms: enhancedPictograms);
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
    }).handleError((error) {
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
    }).handleError((error) {
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
}
