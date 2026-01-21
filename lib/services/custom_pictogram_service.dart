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

  /// Fetch pictograms by category.
  /// 
  /// [categoryId] - The category ID to fetch pictograms for
  /// Returns a list of Pictogram objects
  Future<List<Pictogram>> getPictogramsByCategory(String categoryId) async {
    try {
      debugPrint('Fetching pictograms for category ID: $categoryId');
      // First try with orderBy (requires index)
      try {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('category', isEqualTo: categoryId)
            .where('isActive', isEqualTo: true)
            .orderBy('keyword')
            .get();
        
        debugPrint('Query returned ${querySnapshot.docs.length} documents');

        final pictograms = querySnapshot.docs.map((doc) {
          final data = doc.data();
          final imageUrlStr = data['imageUrl']?.toString() ?? '';
          final imageUrlPreview = imageUrlStr.length > 50 ? '${imageUrlStr.substring(0, 50)}...' : imageUrlStr;
          debugPrint('Pictogram: id=${doc.id}, keyword=${data['keyword']}, category=${data['category']}, imageUrl=$imageUrlPreview');
          
          return Pictogram(
            id: _parsePictogramId(doc.id), // Negative ID for custom pictograms
            keyword: data['keyword'] as String? ?? 'Onbekend',
            category: data['category'] as String? ?? categoryId,
            imageUrl: data['imageUrl'] as String? ?? '', // Cloudinary URL
            description: data['description'] as String?,
          );
        }).toList();
        
        // Sort manually if orderBy fails (fallback)
        pictograms.sort((a, b) => a.keyword.compareTo(b.keyword));
        debugPrint('Returning ${pictograms.length} pictograms for category $categoryId');
        return pictograms;
      } catch (e) {
        debugPrint('OrderBy query failed (index may not be ready): $e');
        // If orderBy fails (index not ready), try without orderBy and sort in memory
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('category', isEqualTo: categoryId)
            .where('isActive', isEqualTo: true)
            .get();
        
        debugPrint('Fallback query returned ${querySnapshot.docs.length} documents');

        final pictograms = querySnapshot.docs.map((doc) {
          final data = doc.data();
          final imageUrlStr = data['imageUrl']?.toString() ?? '';
          final imageUrlPreview = imageUrlStr.length > 50 ? '${imageUrlStr.substring(0, 50)}...' : imageUrlStr;
          debugPrint('Pictogram (fallback): id=${doc.id}, keyword=${data['keyword']}, category=${data['category']}, imageUrl=$imageUrlPreview');
          
          return Pictogram(
            id: _parsePictogramId(doc.id), // Negative ID for custom pictograms
            keyword: data['keyword'] as String? ?? 'Onbekend',
            category: data['category'] as String? ?? categoryId,
            imageUrl: data['imageUrl'] as String? ?? '', // Cloudinary URL
            description: data['description'] as String?,
          );
        }).toList();
        
        // Sort manually
        pictograms.sort((a, b) => a.keyword.compareTo(b.keyword));
        debugPrint('Returning ${pictograms.length} pictograms for category $categoryId (fallback)');
        return pictograms;
      }
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

  /// Search pictograms by keyword
  /// 
  /// [query] - The search query
  /// Returns a list of matching Pictogram objects
  Future<List<Pictogram>> searchPictograms(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('keyword')
          .get();

      final lowerQuery = query.toLowerCase();
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return Pictogram(
              id: -int.parse(doc.id),
              keyword: data['keyword'] as String? ?? 'Onbekend',
              category: data['category'] as String? ?? '',
              imageUrl: data['imageUrl'] as String? ?? '',
              description: data['description'] as String?,
            );
          })
          .where((pictogram) =>
              pictogram.keyword.toLowerCase().contains(lowerQuery) ||
              (pictogram.description?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    } catch (e) {
      return [];
    }
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

  /// Check if a pictogram ID is a custom pictogram.
  /// 
  /// All pictograms are now custom pictograms (negative IDs).
  static bool isCustomPictogram(int id) {
    return id < 0;
  }
}
