import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../config/admin_api.dart';

/// Service for managing pictogram requests.
///
/// Handles submission and retrieval of pictogram requests from users.
/// Collection: picto_requests
class PictoRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name in Firestore
  static const String _collectionName = 'picto_requests';

  /// Submit a pictogram request.
  ///
  /// [keyword] - The requested keyword (required)
  /// [category] - The category key (required)
  /// [description] - Optional description
  /// [requestedBy] - User ID who made the request
  ///
  /// Returns the request document ID if successful, throws exception on error
  Future<String> submitRequest({
    required String keyword,
    required String category,
    String? description,
    required String requestedBy,
  }) async {
    try {
      final requestData = {
        'keyword': keyword.trim(),
        'category': category,
        'description': description?.trim(),
        'requestedBy': requestedBy,
        'status': 'pending', // pending, approved, rejected, completed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection(_collectionName).add(requestData);

      // Email the admins in the background; the request is already saved, so
      // a failure here must not fail the submission.
      unawaited(_notifyAdmins(docRef.id));

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit request: $e');
    }
  }

  /// Asks the admin backend to email the new request to the admins.
  Future<void> _notifyAdmins(String requestId) async {
    if (adminApiBaseUrl.isEmpty) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      final response = await http.post(
        Uri.parse('$adminApiBaseUrl/requests/$requestId/notify'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        debugPrint(
            '[PictoRequestService] Notify failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[PictoRequestService] Notify failed: $e');
    }
  }

  /// Get all requests (for admin panel).
  ///
  /// Returns a stream of all pictogram requests.
  Stream<List<Map<String, dynamic>>> getAllRequests() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Get requests by status.
  ///
  /// [status] - The status to filter by (pending, approved, rejected, completed)
  Stream<List<Map<String, dynamic>>> getRequestsByStatus(String status) {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Get requests by user.
  ///
  /// [userId] - The user ID to filter by
  Stream<List<Map<String, dynamic>>> getUserRequests(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('requestedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Update request status (admin only).
  ///
  /// [requestId] - The request document ID
  /// [status] - New status (pending, approved, rejected, completed)
  /// [adminNote] - Optional admin note
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? adminNote,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminNote != null && adminNote.trim().isNotEmpty) {
        updateData['adminNote'] = adminNote.trim();
      }

      await _firestore
          .collection(_collectionName)
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }
}
