import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';

/// Service for managing caregiver PIN lock system.
/// 
/// Handles PIN hashing, storage, and verification.
/// PINs are stored as SHA-256 hashes in Firestore for security.
/// 
/// Storage location: caregivers/{uid}/settings/pinHash
class PinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID (Firebase UID)
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Hash a PIN using SHA-256.
  /// 
  /// [pin] - The PIN string (4 digits)
  /// Returns the SHA-256 hash as a hex string
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Save PIN hash to Firestore.
  /// 
  /// [pin] - The PIN to save (exactly 4 digits)
  /// Returns true if successful, throws exception on error
  Future<bool> savePin(String pin) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Validate PIN length (exactly 4 digits)
    if (pin.length != 4) {
      throw Exception('PIN must be exactly 4 digits');
    }

    // Validate PIN is numeric only
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw Exception('PIN must contain only numbers');
    }

    try {
      final pinHash = _hashPin(pin);
      
      // Use subcollection path: caregivers/{uid}/settings/settings
      await _firestore
          .collection('caregivers')
          .doc(_currentUserId)
          .collection('settings')
          .doc('settings')
          .set({
        'pinHash': pinHash,
        'pinCreatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      throw Exception('Failed to save PIN: $e');
    }
  }

  /// Verify PIN against stored hash.
  /// 
  /// [pin] - The PIN to verify
  /// Returns true if PIN matches, false otherwise
  Future<bool> verifyPin(String pin) async {
    if (_currentUserId == null) {
      return false;
    }

    try {
      final doc = await _firestore
          .collection('caregivers')
          .doc(_currentUserId)
          .collection('settings')
          .doc('settings')
          .get();
      
      if (!doc.exists) {
        return false; // No PIN set
      }

      final data = doc.data();
      final storedHash = data?['pinHash'] as String?;

      if (storedHash == null) {
        return false; // No PIN hash stored
      }

      final inputHash = _hashPin(pin);
      return inputHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Check if PIN is set for current user.
  /// 
  /// Returns true if PIN exists, false otherwise
  Future<bool> pinExists() async {
    if (_currentUserId == null) {
      return false;
    }

    try {
      final doc = await _firestore
          .collection('caregivers')
          .doc(_currentUserId)
          .collection('settings')
          .doc('settings')
          .get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      return data?['pinHash'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete PIN (for reset/change functionality).
  /// 
  /// Returns true if successful, throws exception on error
  Future<bool> deletePin() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('caregivers')
          .doc(_currentUserId)
          .collection('settings')
          .doc('settings')
          .update({
        'pinHash': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to delete PIN: $e');
    }
  }
}
