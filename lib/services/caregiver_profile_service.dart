import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing caregiver profiles in Firestore.
/// 
/// Handles CRUD operations for caregiver profile data.
/// Collection: caregivers
/// Document ID: Firebase UID
class CaregiverProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection name in Firestore
  static const String _collectionName = 'caregivers';

  /// Get current user ID (Firebase UID)
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Save caregiver profile to Firestore.
  /// 
  /// Creates or updates the caregiver document using Firebase UID as document ID.
  /// 
  /// [name] - Caregiver's full name
  /// [role] - Caregiver's role (Parent, Teacher, Therapist)
  /// [clientName] - Name of the client (optional)
  /// [ageRange] - Client's age range (optional)
  /// [language] - Preferred language (default: 'nl')
  /// 
  /// Returns true if successful, throws exception on error
  Future<bool> saveProfile({
    required String name,
    required String role,
    String? clientName,
    String? ageRange,
    String language = 'nl',
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final profileData = {
        'name': name.trim(),
        'role': role,
        'language': language,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields if provided
      if (clientName != null && clientName.trim().isNotEmpty) {
        profileData['clientName'] = clientName.trim();
      }
      if (ageRange != null && ageRange.isNotEmpty) {
        profileData['ageRange'] = ageRange;
      }

      await _firestore
          .collection(_collectionName)
          .doc(_currentUserId)
          .set(profileData, SetOptions(merge: true));

      return true;
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Get caregiver profile from Firestore.
  /// 
  /// Returns the caregiver document data or null if not found.
  Future<Map<String, dynamic>?> getProfile() async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_currentUserId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Check if caregiver profile exists.
  /// 
  /// Returns true if profile document exists, false otherwise.
  Future<bool> profileExists() async {
    if (_currentUserId == null) {
      return false;
    }

    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_currentUserId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
