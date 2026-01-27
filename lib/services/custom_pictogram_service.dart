import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/pictogram_model.dart';

/// Service for managing custom pictograms stored in Firestore.
/// 
/// All pictograms are now custom pictograms uploaded by admins via the admin panel.
/// Images are stored in Cloudinary and URLs are stored in Firestore.
class CustomPictogramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name for custom pictograms
  static const String _collectionName = 'custom_pictograms';

  /// Fetch pictograms by category, ordered alphabetically by keyword.
  /// 
  /// [categoryId] - The category ID to fetch pictograms for
  /// Returns a list of Pictogram objects sorted alphabetically by keyword
  Future<List<Pictogram>> getPictogramsByCategory(String categoryId) async {
    try {
      debugPrint('Fetching pictograms for category ID: $categoryId');
      
      // Fetch all pictograms for the category
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('category', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('Query returned ${querySnapshot.docs.length} documents');

      // Map to Pictogram objects
      final pictograms = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        debugPrint('Pictogram: id=${doc.id}, keyword=${data['keyword']}, category=${data['category']}');
        
        return Pictogram(
          id: _parsePictogramId(doc.id), // Negative ID for custom pictograms
          keyword: data['keyword'] as String? ?? 'Onbekend',
          category: data['category'] as String? ?? categoryId,
          imageUrl: data['imageUrl'] as String? ?? '', // Cloudinary URL
          description: data['description'] as String?,
        );
      }).toList();
      
      // Sort alphabetically by keyword (ascending)
      pictograms.sort((a, b) => a.keyword.compareTo(b.keyword));
      
      debugPrint('Returning ${pictograms.length} pictograms for category $categoryId (sorted alphabetically)');
      return pictograms;
    } catch (e) {
      // Return empty list on error, but log detailed error
      debugPrint('Error fetching pictograms by category ($categoryId): $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}, message: ${e.message}');
      }
      return [];
    }
  }

  /// Increment usage count for a pictogram when it's used in a set.
  /// 
  /// [pictogramId] - The Firestore document ID of the pictogram
  /// This is called when a pictogram is added to a set to track popularity
  Future<void> incrementUsageCount(String pictogramId) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(pictogramId);
      
      // Use FieldValue.increment to atomically increment the count
      await docRef.update({
        'usageCount': FieldValue.increment(1),
        'lastUsedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Incremented usage count for pictogram: $pictogramId');
    } catch (e) {
      // Log error but don't throw - usage tracking shouldn't break the app
      debugPrint('Error incrementing usage count for $pictogramId: $e');
    }
  }

  /// Increment usage count for multiple pictograms (batch operation).
  /// 
  /// [pictogramIds] - List of Firestore document IDs
  /// This is more efficient when adding multiple pictograms to a set
  Future<void> incrementUsageCountBatch(List<String> pictogramIds) async {
    if (pictogramIds.isEmpty) return;
    
    try {
      final batch = _firestore.batch();
      
      for (final pictogramId in pictogramIds) {
        final docRef = _firestore.collection(_collectionName).doc(pictogramId);
        batch.update(docRef, {
          'usageCount': FieldValue.increment(1),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      debugPrint('Incremented usage count for ${pictogramIds.length} pictograms');
    } catch (e) {
      // Log error but don't throw - usage tracking shouldn't break the app
      debugPrint('Error incrementing usage count batch: $e');
    }
  }

  /// Fetch all pictograms.
  /// 
  /// Returns a list of all active pictograms
  Future<List<Pictogram>> getAllPictograms() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('keyword')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Pictogram(
          id: -int.parse(doc.id), // Negative ID for custom pictograms
          keyword: data['keyword'] as String? ?? 'Onbekend',
          category: data['category'] as String? ?? '',
          imageUrl: data['imageUrl'] as String? ?? '', // Cloudinary URL
          description: data['description'] as String?,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search pictograms by keyword across the entire library
  /// 
  /// Searches all active pictograms regardless of category.
  /// Handles both Dutch and English keywords with proper case-insensitive matching.
  /// The search is language-agnostic and works with Dutch keywords stored in Firestore.
  /// [query] - The search query (can be in any language)
  /// Returns a list of matching Pictogram objects from all categories
  Future<List<Pictogram>> searchPictograms(String query) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return [];
      }

      debugPrint('Searching for: "$trimmedQuery"');
      
      // Search all active pictograms across all categories
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('keyword')
          .get();

      debugPrint('Found ${querySnapshot.docs.length} total active pictograms to search');

      // Normalize query for better matching (remove accents, convert to lowercase)
      final normalizedQuery = _normalizeString(trimmedQuery.toLowerCase());
      
      final results = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            final keyword = data['keyword'] as String? ?? 'Onbekend';
            return Pictogram(
              id: _parsePictogramId(doc.id),
              keyword: keyword,
              category: data['category'] as String? ?? '',
              imageUrl: data['imageUrl'] as String? ?? '',
              description: data['description'] as String?,
            );
          })
          .where((pictogram) {
            // Normalize keyword and description for comparison
            final normalizedKeyword = _normalizeString(pictogram.keyword.toLowerCase());
            final normalizedDescription = pictogram.description != null
                ? _normalizeString(pictogram.description!.toLowerCase())
                : '';
            
            // Check if query matches keyword or description (case-insensitive, accent-insensitive)
            final matchesKeyword = normalizedKeyword.contains(normalizedQuery);
            final matchesDescription = normalizedDescription.isNotEmpty && 
                                      normalizedDescription.contains(normalizedQuery);
            
            if (matchesKeyword || matchesDescription) {
              debugPrint('Match found: keyword="${pictogram.keyword}" (normalized: "$normalizedKeyword")');
            }
            
            return matchesKeyword || matchesDescription;
          })
          .toList();
      
      debugPrint('Search returned ${results.length} matching pictograms');
      return results;
    } catch (e) {
      debugPrint('Error searching pictograms: $e');
      return [];
    }
  }

  /// Normalize string by removing accents and special characters for better search matching
  /// This helps with searching Dutch keywords that may have accents
  String _normalizeString(String input) {
    // Remove common accents and normalize characters
    return input
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ÿ', 'y')
        .trim();
  }

  /// Parse document ID to integer (negative for custom pictograms)
  /// Handles both numeric and non-numeric document IDs
  int _parsePictogramId(String docId) {
    try {
      return -int.parse(docId);
    } catch (e) {
      // If document ID is not numeric, use hash code
      return -docId.hashCode;
    }
  }

  /// Get Firestore document ID from a Pictogram.
  /// 
  /// Since Pictogram.id is negative for custom pictograms, we need to reverse it.
  /// For non-numeric document IDs, we query Firestore by imageUrl (which should be unique).
  /// [pictogram] - The Pictogram to find the document ID for
  /// Returns the Firestore document ID, or null if not found
  Future<String?> getPictogramDocumentId(Pictogram pictogram) async {
    try {
      // If the ID is negative, try to reverse it
      if (pictogram.id < 0) {
        final positiveId = -pictogram.id;
        
        // Try to parse as document ID (if it was originally numeric)
        try {
          final docId = positiveId.toString();
          final doc = await _firestore.collection(_collectionName).doc(docId).get();
          if (doc.exists) {
            return docId;
          }
        } catch (e) {
          // Not a numeric ID, continue to query by imageUrl
        }
      }
      
      // If reverse parsing didn't work, query by imageUrl (should be unique)
      if (pictogram.imageUrl.isNotEmpty) {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('imageUrl', isEqualTo: pictogram.imageUrl)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.id;
        }
      }
      
      // Fallback: query by keyword and category
      if (pictogram.keyword.isNotEmpty && pictogram.category.isNotEmpty) {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('keyword', isEqualTo: pictogram.keyword)
            .where('category', isEqualTo: pictogram.category)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.id;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting document ID for pictogram: $e');
      return null;
    }
  }

  /// Get Firestore document IDs for multiple pictograms (batch lookup).
  /// 
  /// More efficient than calling getPictogramDocumentId multiple times.
  /// [pictograms] - List of Pictograms to find document IDs for
  /// Returns a map of Pictogram.id -> document ID
  Future<Map<int, String>> getPictogramDocumentIds(List<Pictogram> pictograms) async {
    final result = <int, String>{};
    
    if (pictograms.isEmpty) return result;
    
    try {
      // Group by imageUrl for efficient querying
      final imageUrlMap = <String, List<Pictogram>>{};
      final keywordCategoryMap = <String, List<Pictogram>>{};
      
      for (final pictogram in pictograms) {
        if (pictogram.imageUrl.isNotEmpty) {
          imageUrlMap.putIfAbsent(pictogram.imageUrl, () => []).add(pictogram);
        } else if (pictogram.keyword.isNotEmpty && pictogram.category.isNotEmpty) {
          final key = '${pictogram.keyword}|${pictogram.category}';
          keywordCategoryMap.putIfAbsent(key, () => []).add(pictogram);
        }
      }
      
      // Query by imageUrl (most reliable)
      for (final entry in imageUrlMap.entries) {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('imageUrl', isEqualTo: entry.key)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;
          for (final pictogram in entry.value) {
            result[pictogram.id] = docId;
          }
        }
      }
      
      // Query by keyword+category for pictograms without imageUrl
      for (final entry in keywordCategoryMap.entries) {
        final parts = entry.key.split('|');
        if (parts.length == 2) {
          final querySnapshot = await _firestore
              .collection(_collectionName)
              .where('keyword', isEqualTo: parts[0])
              .where('category', isEqualTo: parts[1])
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            final docId = querySnapshot.docs.first.id;
            for (final pictogram in entry.value) {
              if (!result.containsKey(pictogram.id)) {
                result[pictogram.id] = docId;
              }
            }
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting document IDs for pictograms: $e');
      return result;
    }
  }

  /// Check if a pictogram ID is a custom pictogram.
  /// 
  /// All pictograms are now custom pictograms (negative IDs).
  static bool isCustomPictogram(int id) {
    return id < 0;
  }
}
