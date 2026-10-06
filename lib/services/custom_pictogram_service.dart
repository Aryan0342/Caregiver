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

  /// How long the pictogram catalog is reused before it is fetched again.
  static const Duration _catalogMaxAge = Duration(minutes: 30);

  // All active pictograms, fetched with a single query and shared by every
  // screen (categories, category lists, search, library) to save data.
  static List<_CatalogEntry>? _catalog;
  static DateTime? _catalogLoadedAt;
  static Future<List<_CatalogEntry>>? _catalogRequest;

  /// Forgets the cached catalog so the next call fetches it again.
  static void clearCache() {
    _catalog = null;
    _catalogLoadedAt = null;
  }

  Future<List<_CatalogEntry>> _getCatalog() {
    final loadedAt = _catalogLoadedAt;
    if (_catalog != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _catalogMaxAge) {
      return Future.value(_catalog);
    }
    // Share one request between callers that ask at the same time.
    return _catalogRequest ??= _fetchCatalog().whenComplete(() {
      _catalogRequest = null;
    });
  }

  Future<List<_CatalogEntry>> _fetchCatalog() async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .get();
    debugPrint(
        'Fetched pictogram catalog: ${querySnapshot.docs.length} pictograms');

    final catalog = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final categoryId = data['category'] as String? ?? '';
      return _CatalogEntry(
        docId: doc.id,
        categoryId: categoryId,
        pictogram: Pictogram(
          id: _parsePictogramId(doc.id), // Negative ID for custom pictograms
          keyword: data['keyword'] as String? ?? 'Onbekend',
          category: categoryId,
          imageUrl: data['imageUrl'] as String? ?? '', // Cloudinary URL
          description: data['description'] as String?,
        ),
      );
    }).toList();

    _catalog = catalog;
    _catalogLoadedAt = DateTime.now();
    return catalog;
  }

  /// IDs of the categories that have at least one active pictogram.
  Future<Set<String>> getCategoryIdsWithPictograms() async {
    final catalog = await _getCatalog();
    return catalog.map((entry) => entry.categoryId).toSet();
  }

  /// Fetch pictograms by category, ordered alphabetically by keyword.
  ///
  /// [categoryId] - The category ID to fetch pictograms for
  /// Returns a list of Pictogram objects sorted alphabetically by keyword
  Future<List<Pictogram>> getPictogramsByCategory(String categoryId) async {
    try {
      final catalog = await _getCatalog();
      final pictograms = catalog
          .where((entry) => entry.categoryId == categoryId)
          .map((entry) => entry.pictogram)
          .toList()
        ..sort((a, b) => a.keyword.compareTo(b.keyword));
      return removeDuplicates(pictograms);
    } catch (e) {
      // Return empty list on error, but log detailed error
      debugPrint('Error fetching pictograms by category ($categoryId): $e');
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
      debugPrint(
          'Incremented usage count for ${pictogramIds.length} pictograms');
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
      final catalog = await _getCatalog();
      final pictograms = catalog.map((entry) => entry.pictogram).toList()
        ..sort((a, b) => a.keyword.compareTo(b.keyword));
      return removeDuplicates(pictograms);
    } catch (e) {
      return [];
    }
  }

  /// Search pictograms by keyword across the entire library (all categories).
  ///
  /// Searches keyword and description (case- and accent-insensitive) in the
  /// cached catalog, so typing a search does not download the collection.
  /// [query] - The search query (any language)
  /// Returns matching Pictogram objects from all categories, sorted by keyword.
  Future<List<Pictogram>> searchPictograms(String query) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return [];
      }

      final catalog = await _getCatalog();
      final normalizedQuery = _normalizeString(trimmedQuery.toLowerCase());

      final results =
          catalog.map((entry) => entry.pictogram).where((pictogram) {
        final normalizedKeyword =
            _normalizeString(pictogram.keyword.toLowerCase());
        final normalizedDescription = pictogram.description != null
            ? _normalizeString(pictogram.description!.toLowerCase())
            : '';
        final matchesKeyword = normalizedKeyword.contains(normalizedQuery);
        final matchesDescription = normalizedDescription.isNotEmpty &&
            normalizedDescription.contains(normalizedQuery);
        return matchesKeyword || matchesDescription;
      }).toList();

      results.sort((a, b) => a.keyword.compareTo(b.keyword));
      return removeDuplicates(results);
    } catch (e) {
      debugPrint('Error searching pictograms: $e');
      return [];
    }
  }

  /// Normalize string by removing accents and special characters for better search matching
  /// This helps with searching Dutch keywords that may have accents
  static String _normalizeString(String input) {
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
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim();
  }

  /// Parse document ID to integer (negative for custom pictograms)
  /// Handles both numeric and non-numeric document IDs
  /// Removes pictograms that appear more than once, e.g. when the same
  /// pictogram was uploaded twice. Pictograms with the same keyword (ignoring
  /// case, accents and extra spaces) count as duplicates; the first one with
  /// an image is kept. Order is preserved.
  static List<Pictogram> removeDuplicates(List<Pictogram> pictograms) {
    final byKey = <String, int>{};
    final unique = <Pictogram>[];
    for (final pictogram in pictograms) {
      final key = _normalizeString(pictogram.keyword.toLowerCase())
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');
      final existingIndex = byKey[key];
      if (existingIndex == null) {
        byKey[key] = unique.length;
        unique.add(pictogram);
      } else if (unique[existingIndex].imageUrl.isEmpty &&
          pictogram.imageUrl.isNotEmpty) {
        unique[existingIndex] = pictogram;
      }
    }
    return unique;
  }

  static int _parsePictogramId(String docId) {
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
      final cached = _catalogDocumentId(pictogram);
      if (cached != null) return cached;

      // If the ID is negative, try to reverse it
      if (pictogram.id < 0) {
        final positiveId = -pictogram.id;

        // Try to parse as document ID (if it was originally numeric)
        try {
          final docId = positiveId.toString();
          final doc =
              await _firestore.collection(_collectionName).doc(docId).get();
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
  Future<Map<int, String>> getPictogramDocumentIds(
      List<Pictogram> pictograms) async {
    final result = <int, String>{};

    if (pictograms.isEmpty) return result;

    try {
      // Resolve from the cached catalog first; only query the rest.
      final remaining = <Pictogram>[];
      for (final pictogram in pictograms) {
        final cached = _catalogDocumentId(pictogram);
        if (cached != null) {
          result[pictogram.id] = cached;
        } else {
          remaining.add(pictogram);
        }
      }
      pictograms = remaining;
      if (pictograms.isEmpty) return result;

      // Group by imageUrl for efficient querying
      final imageUrlMap = <String, List<Pictogram>>{};
      final keywordCategoryMap = <String, List<Pictogram>>{};

      for (final pictogram in pictograms) {
        if (pictogram.imageUrl.isNotEmpty) {
          imageUrlMap.putIfAbsent(pictogram.imageUrl, () => []).add(pictogram);
        } else if (pictogram.keyword.isNotEmpty &&
            pictogram.category.isNotEmpty) {
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

  /// Document ID of [pictogram] from the cached catalog, if loaded.
  static String? _catalogDocumentId(Pictogram pictogram) {
    final catalog = _catalog;
    if (catalog == null) return null;
    for (final entry in catalog) {
      if (entry.pictogram.id == pictogram.id ||
          (pictogram.imageUrl.isNotEmpty &&
              entry.pictogram.imageUrl == pictogram.imageUrl)) {
        return entry.docId;
      }
    }
    return null;
  }

  /// Check if a pictogram ID is a custom pictogram.
  ///
  /// All pictograms are now custom pictograms (negative IDs).
  static bool isCustomPictogram(int id) {
    return id < 0;
  }
}

/// A pictogram in the cached catalog with its Firestore document and category.
class _CatalogEntry {
  final String docId;
  final String categoryId;
  final Pictogram pictogram;

  const _CatalogEntry({
    required this.docId,
    required this.categoryId,
    required this.pictogram,
  });
}
