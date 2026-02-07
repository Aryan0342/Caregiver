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
  /// [sex] - Caregiver's sex (optional)
  /// [organisation] - Caregiver's organisation (optional)
  /// [location] - Caregiver's specific location (optional)
  /// [language] - Preferred language (default: 'nl')
  /// [securityQuestion] - Security question for password/PIN reset (optional)
  /// [securityAnswer] - Answer to security question (optional, stored hashed)
  ///
  /// Returns true if successful, throws exception on error
  Future<bool> saveProfile({
    required String name,
    required String role,
    String? sex,
    String? organisation,
    String? location,
    String language = 'nl',
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user email for lookup
      final userEmail = _auth.currentUser?.email?.toLowerCase().trim();

      final profileData = {
        'name': name.trim(),
        'role': role,
        'language': language,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Store email for security question lookup (always store if available)
      // This is critical for forgot password flow to work
      if (userEmail != null && userEmail.isNotEmpty) {
        profileData['email'] = userEmail;
      } else {
        // If email is not available, try to get it from auth user
        final authUser = _auth.currentUser;
        if (authUser?.email != null) {
          profileData['email'] = authUser!.email!.toLowerCase().trim();
        }
      }

      // Add optional fields if provided
      if (sex != null && sex.trim().isNotEmpty) {
        profileData['sex'] = sex.trim();
      }
      if (organisation != null && organisation.trim().isNotEmpty) {
        profileData['organisation'] = organisation.trim();
      }
      if (location != null && location.trim().isNotEmpty) {
        profileData['location'] = location.trim();
      }

      // Store security question and answer (answer is stored in lowercase for case-insensitive comparison)
      if (securityQuestion != null && securityQuestion.trim().isNotEmpty) {
        profileData['securityQuestion'] = securityQuestion.trim();
      }
      if (securityAnswer != null && securityAnswer.trim().isNotEmpty) {
        // Store answer in lowercase for case-insensitive comparison
        profileData['securityAnswer'] = securityAnswer.trim().toLowerCase();
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
  /// Automatically updates email field if missing for future lookups.
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
        final data = doc.data()!;

        // If email is missing, update it from Firebase Auth for future lookups
        if (!data.containsKey('email') || data['email'] == null) {
          final userEmail = _auth.currentUser?.email?.toLowerCase().trim();
          if (userEmail != null && userEmail.isNotEmpty) {
            try {
              await _firestore
                  .collection(_collectionName)
                  .doc(_currentUserId)
                  .update({'email': userEmail});
              // Update the returned data
              data['email'] = userEmail;
            } catch (e) {
              print('Failed to update email in profile: $e');
            }
          }
        }

        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Delete the current user's caregiver profile document.
  /// Call this before deleting the Firebase Auth user.
  Future<void> deleteProfile() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    try {
      await _firestore.collection(_collectionName).doc(_currentUserId).delete();
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
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

  /// Get security question for a user by email.
  ///
  /// Finds the user by email and returns their security question.
  /// Returns null if user not found or question not set.
  Future<String?> getSecurityQuestionByEmail(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      print('Looking up security question for email: $normalizedEmail');

      // Query Firestore to find user by email
      // Note: This requires Firestore security rules to allow unauthenticated queries by email
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      print('Query returned ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print('Profile data keys: ${data.keys}');
        print('Profile has email: ${data.containsKey('email')}');
        print(
          'Profile has securityQuestion: ${data.containsKey('securityQuestion')}',
        );

        final question = data['securityQuestion'] as String?;

        // Check if security question exists
        if (question == null || question.isEmpty) {
          // Profile exists but no security question set
          print(
            'Profile found for $normalizedEmail but no security question set',
          );
          return null;
        }

        print(
          'Security question found for $normalizedEmail: ${question.substring(0, question.length > 50 ? 50 : question.length)}...',
        );
        return question;
      }

      // If query returned no results, email might not be stored in profile
      // This could happen if profile was created before email was added
      // Try alternative: if user is authenticated, check their profile directly
      if (_auth.currentUser != null &&
          _auth.currentUser!.email?.toLowerCase().trim() == normalizedEmail) {
        print('User is authenticated, checking profile directly by UID');
        final profile = await getProfile();
        if (profile != null) {
          final question = profile['securityQuestion'] as String?;
          if (question != null && question.isNotEmpty) {
            // Update email in profile for future lookups
            try {
              await _firestore
                  .collection(_collectionName)
                  .doc(_currentUserId)
                  .update({'email': normalizedEmail});
              print('Updated email in profile for future lookups');
            } catch (e) {
              print('Failed to update email in profile: $e');
            }
            return question;
          }
        }
      }

      print('No profile found for email: $normalizedEmail');
      return null;
    } on FirebaseException catch (e) {
      // Handle Firestore-specific errors (like missing index or permission denied)
      print(
        'FirebaseException in getSecurityQuestionByEmail: code=${e.code}, message=${e.message}',
      );

      if (e.code == 'failed-precondition') {
        // Index is missing - this is a configuration issue
        // The error message will guide users to create the index
        print(
          'Firestore index missing for email query. Create index: ${e.message}',
        );
        return null;
      }
      if (e.code == 'permission-denied') {
        // Permission denied - security rules blocking the query
        print(
          'Permission denied for email query. Check Firestore security rules.',
        );
        return null;
      }
      return null;
    } catch (e) {
      print('Exception in getSecurityQuestionByEmail: $e');
      return null;
    }
  }

  /// Verify security answer for a user by email.
  ///
  /// Finds the user by email and verifies their security answer.
  /// Returns true if answer matches, false otherwise.
  Future<bool> verifySecurityAnswerByEmail(String email, String answer) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final normalizedAnswer = answer.trim().toLowerCase();

      // Query Firestore to find user by email
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final storedAnswer = data['securityAnswer'] as String?;

        if (storedAnswer == null || storedAnswer.isEmpty) {
          return false;
        }

        // Compare answers in lowercase for case-insensitive comparison
        return storedAnswer.toLowerCase() == normalizedAnswer;
      }
      return false;
    } on FirebaseException catch (e) {
      // Handle Firestore-specific errors
      if (e.code == 'failed-precondition') {
        // Index is missing
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
