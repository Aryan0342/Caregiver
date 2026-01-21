import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing pictogram categories in Firestore.
/// 
/// Categories are created and managed by admins through the admin panel.
/// Only categories that have at least one pictogram are shown in the app.
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name for categories
  static const String _collectionName = 'categories';

  /// Fetch all categories that have at least one active pictogram.
  /// 
  /// Returns a list of category objects with their metadata
  Future<List<Category>> getCategoriesWithPictograms() async {
    try {
      // Get all categories
      final categoriesSnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final categories = <Category>[];

      // Check each category to see if it has pictograms
      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final categoryId = doc.id;
        
        // Check if category has at least one active pictogram
        final pictogramsSnapshot = await _firestore
            .collection('custom_pictograms')
            .where('category', isEqualTo: categoryId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        // Only include categories that have at least one pictogram
        if (pictogramsSnapshot.docs.isNotEmpty) {
          categories.add(Category(
            id: categoryId,
            name: data['name'] as String? ?? '',
            nameEn: data['nameEn'] as String? ?? '',
            nameNl: data['nameNl'] as String? ?? '',
            description: data['description'] as String?,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
          ));
        }
      }

      return categories;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Fetch all categories (including empty ones) - for admin use
  Future<List<Category>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Category(
          id: doc.id,
          name: data['name'] as String? ?? '',
          nameEn: data['nameEn'] as String? ?? '',
          nameNl: data['nameNl'] as String? ?? '',
          description: data['description'] as String?,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(categoryId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return Category(
        id: doc.id,
        name: data['name'] as String? ?? '',
        nameEn: data['nameEn'] as String? ?? '',
        nameNl: data['nameNl'] as String? ?? '',
        description: data['description'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Model representing a pictogram category
class Category {
  final String id;
  final String name;
  final String nameEn;
  final String nameNl;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameNl,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// Get localized name based on language code
  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'nl') {
      return nameNl.isNotEmpty ? nameNl : name;
    } else {
      return nameEn.isNotEmpty ? nameEn : name;
    }
  }
}
