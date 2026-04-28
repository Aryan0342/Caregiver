import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pictogram_model.dart';
import '../models/set_model.dart';

class SetShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _shareCollection = 'pictogram_set_shares';
  static const String _setCollection = 'pictogram_sets';
  static const List<String> _tokenParameterNames = [
    'token',
    'share',
    'shareId',
    'setId',
    'id',
    'docId',
    'documentId',
  ];

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<String> createShareLink(PictogramSet set) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _firestore.collection(_shareCollection).doc();
    await docRef.set({
      'name': set.name,
      'pictograms': set.pictograms.map((p) => p.toJson()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': _currentUserId,
    });

    return 'https://caregiver.app/share?token=${docRef.id}';
  }

  Future<void> importSharedSet(String linkOrToken) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final token = _extractToken(linkOrToken);
    if (token == null || token.isEmpty) {
      throw Exception('Invalid share link');
    }

    final doc = await _firestore.collection(_shareCollection).doc(token).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Share link not found');
    }

    final data = doc.data()!;
    final name = data['name'] as String? ?? 'Shared set';
    final pictograms = (data['pictograms'] as List<dynamic>? ?? [])
        .map((p) => Pictogram.fromJson(p as Map<String, dynamic>))
        .toList();

    final newSet = PictogramSet(
      id: '',
      name: name,
      userId: _currentUserId!,
      pictograms: pictograms,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_setCollection).doc().set(newSet.toJson());
  }

  String? _extractToken(String linkOrToken) {
    final trimmed = linkOrToken.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final urlMatch = RegExp(
      r'''https?://[^\s<>"']+''',
      caseSensitive: false,
    ).firstMatch(trimmed);

    final candidate = urlMatch?.group(0) ?? trimmed;
    final uri = Uri.tryParse(candidate);
    if (uri != null) {
      for (final parameterName in _tokenParameterNames) {
        final value = uri.queryParameters[parameterName];
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      for (final segment in uri.pathSegments.reversed) {
        if (segment.isNotEmpty && segment.toLowerCase() != 'share') {
          return segment;
        }
      }
    }

    final queryMatch = RegExp(
      r'(?i)(?:token|shareId|setId|id|docId|documentId)=([A-Za-z0-9_-]+)',
    ).firstMatch(trimmed);
    if (queryMatch != null) {
      return queryMatch.group(1);
    }

    if (RegExp(r'^[A-Za-z0-9_-]{8,}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }
}
