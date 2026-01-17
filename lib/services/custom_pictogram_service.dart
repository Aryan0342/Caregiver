import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pictogram_model.dart';

/// Service for managing custom pictograms stored in Firestore.
/// 
/// Custom pictograms are uploaded by admins and stored separately from ARASAAC pictograms.
/// They are merged with ARASAAC results when searching by category.
class CustomPictogramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name for custom pictograms
  static const String _collectionName = 'custom_pictograms';

  /// Fetch custom pictograms by category.
  /// 
  /// [category] - The category to fetch custom pictograms for
  /// Returns a list of custom Pictogram objects
  Future<List<Pictogram>> getCustomPictogramsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Pictogram(
          id: -int.parse(doc.id), // Negative ID to distinguish from ARASAAC pictograms
          keyword: data['keyword'] as String? ?? 'Onbekend',
          category: data['category'] as String? ?? category,
          imageUrl: data['imageUrl'] as String? ?? '',
          description: data['description'] as String?,
        );
      }).toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Fetch all custom pictograms.
  /// 
  /// Returns a list of all active custom pictograms
  Future<List<Pictogram>> getAllCustomPictograms() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Pictogram(
          id: -int.parse(doc.id), // Negative ID to distinguish from ARASAAC pictograms
          keyword: data['keyword'] as String? ?? 'Onbekend',
          category: data['category'] as String? ?? 'diversen',
          imageUrl: data['imageUrl'] as String? ?? '',
          description: data['description'] as String?,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a pictogram ID is a custom pictogram.
  /// 
  /// Custom pictograms have negative IDs to distinguish them from ARASAAC pictograms.
  static bool isCustomPictogram(int id) {
    return id < 0;
  }
}
