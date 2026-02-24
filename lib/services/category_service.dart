import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
      debugPrint('CategoryService: Fetching categories...');

      // First, try to get all categories (with or without isActive filter)
      QuerySnapshot categoriesSnapshot;
      try {
        // Try with isActive filter first
        categoriesSnapshot = await _firestore
            .collection(_collectionName)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();
        debugPrint(
            'CategoryService: Found ${categoriesSnapshot.docs.length} active categories');
      } catch (e) {
        debugPrint(
            'CategoryService: isActive filter failed, trying without filter: $e');
        // If orderBy fails (index not ready), try without orderBy
        try {
          categoriesSnapshot = await _firestore
              .collection(_collectionName)
              .where('isActive', isEqualTo: true)
              .get();
          debugPrint(
              'CategoryService: Found ${categoriesSnapshot.docs.length} active categories (without orderBy)');
        } catch (e2) {
          debugPrint(
              'CategoryService: isActive query failed, trying to get all categories: $e2');
          // If isActive field doesn't exist, get all categories
          categoriesSnapshot =
              await _firestore.collection(_collectionName).get();
          debugPrint(
              'CategoryService: Found ${categoriesSnapshot.docs.length} total categories');
        }
      }

      final categories = <Category>[];

      // Check each category to see if it has pictograms
      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final categoryId = doc.id;

        debugPrint(
            'CategoryService: Checking category: $categoryId (name: ${data['name'] ?? 'N/A'})');

        // Check if category has at least one active pictogram
        try {
          final pictogramsSnapshot = await _firestore
              .collection('custom_pictograms')
              .where('category', isEqualTo: categoryId)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

          debugPrint(
              'CategoryService: Category $categoryId has ${pictogramsSnapshot.docs.length} active pictograms');

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
            debugPrint('CategoryService: Added category $categoryId to list');
          } else {
            // Try without isActive filter for pictograms
            debugPrint(
                'CategoryService: No active pictograms found, trying without isActive filter...');
            final allPictogramsSnapshot = await _firestore
                .collection('custom_pictograms')
                .where('category', isEqualTo: categoryId)
                .limit(1)
                .get();

            if (allPictogramsSnapshot.docs.isNotEmpty) {
              debugPrint(
                  'CategoryService: Found ${allPictogramsSnapshot.docs.length} pictograms (without isActive filter)');
              categories.add(Category(
                id: categoryId,
                name: data['name'] as String? ?? '',
                nameEn: data['nameEn'] as String? ?? '',
                nameNl: data['nameNl'] as String? ?? '',
                description: data['description'] as String?,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
              ));
              debugPrint(
                  'CategoryService: Added category $categoryId to list (without isActive filter)');
            }
          }
        } catch (e) {
          debugPrint(
              'CategoryService: Error checking pictograms for category $categoryId: $e');
          // Continue to next category
        }
      }

      debugPrint(
          'CategoryService: Returning ${categories.length} categories with pictograms');
      return categories;
    } catch (e, stackTrace) {
      debugPrint('CategoryService: Error in getCategoriesWithPictograms: $e');
      debugPrint('CategoryService: Stack trace: $stackTrace');
      // Return empty list on error
      return [];
    }
  }

  /// Fetch all categories (including empty ones) - for admin use
  Future<List<Category>> getAllCategories() async {
    try {
      debugPrint('CategoryService: Fetching all categories from Firestore...');
      final querySnapshot = await _firestore.collection(_collectionName).get();

      debugPrint(
          'CategoryService: Found ${querySnapshot.docs.length} categories');

      final categories = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint(
            'CategoryService: Category ${doc.id} - name: ${data['name']}, nameEn: ${data['nameEn']}, nameNl: ${data['nameNl']}');
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

      // Filter out categories without names and sort
      final validCategories = categories
          .where((c) =>
              c.name.isNotEmpty || c.nameEn.isNotEmpty || c.nameNl.isNotEmpty)
          .toList();
      validCategories.sort((a, b) => (a.name.isEmpty ? a.nameEn : a.name)
          .compareTo(b.name.isEmpty ? b.nameEn : b.name));

      return validCategories;
    } catch (e, stackTrace) {
      debugPrint('CategoryService: Error fetching categories: $e');
      debugPrint('CategoryService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get a category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(categoryId).get();

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
