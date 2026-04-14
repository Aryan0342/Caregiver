import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client_profile_model.dart';

/// Service for managing caregiver clients in Firestore.
class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _caregiversCollection = 'caregivers';
  static const String _settingsCollection = 'settings';
  static const String _clientType = 'client_profile';

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _settingsRefForUser(String userId) {
    return _firestore
        .collection(_caregiversCollection)
        .doc(userId)
        .collection(_settingsCollection);
  }

  Stream<List<ClientProfile>> getUserClients() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _settingsRefForUser(userId)
        .where('type', isEqualTo: _clientType)
        .snapshots()
        .map((snapshot) {
      final clients = snapshot.docs
          .map((doc) => ClientProfile.fromJson(doc.id, doc.data()))
          .toList();
      clients
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return clients;
    });
  }

  Future<String> createClient({
    required String name,
    String? phoneNumber,
    String? email,
    String? note,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _settingsRefForUser(userId).doc();
    final now = DateTime.now();

    await docRef.set({
      'type': _clientType,
      'caregiverId': userId,
      'name': name.trim(),
      'phoneNumber':
          phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    return docRef.id;
  }

  Future<void> updateClient({
    required String clientId,
    required String name,
    String? phoneNumber,
    String? email,
    String? note,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _settingsRefForUser(userId).doc(clientId);
    final now = DateTime.now();

    await docRef.update({
      'name': name.trim(),
      'phoneNumber':
          phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
      'updatedAt': now.toIso8601String(),
    });
  }

  Future<void> deleteClient(String clientId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _settingsRefForUser(userId).doc(clientId).delete();
  }

  Future<int> getClientProgress({
    required String clientId,
    required String setId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _settingsRefForUser(userId).doc(clientId).get();
    if (!doc.exists) return 0;

    final data = doc.data();
    if (data == null) return 0;

    final raw = data['sessionProgress'];
    if (raw is! Map<String, dynamic>) return 0;

    final index = raw[setId];
    if (index is int) return index;
    if (index is num) return index.toInt();
    return 0;
  }

  Future<void> saveClientProgress({
    required String clientId,
    required String setId,
    required int index,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _settingsRefForUser(userId).doc(clientId);
    await docRef.set({
      'sessionProgress': {setId: index},
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
