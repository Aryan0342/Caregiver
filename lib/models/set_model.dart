import 'pictogram_model.dart';

/// Model representing a pictogram set (pictoreeks)
class PictogramSet {
  final String id;
  final String name;
  final String userId;
  final List<Pictogram> pictograms;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAutoSaved;

  const PictogramSet({
    required this.id,
    required this.name,
    required this.userId,
    required this.pictograms,
    required this.createdAt,
    this.updatedAt,
    this.isAutoSaved = false,
  });

  /// Create a copy with updated values
  PictogramSet copyWith({
    String? id,
    String? name,
    String? userId,
    List<Pictogram>? pictograms,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAutoSaved,
  }) {
    return PictogramSet(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      pictograms: pictograms ?? this.pictograms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAutoSaved: isAutoSaved ?? this.isAutoSaved,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userId': userId,
      'pictograms': pictograms.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAutoSaved': isAutoSaved,
    };
  }

  /// Create from Firestore document
  factory PictogramSet.fromJson(String id, Map<String, dynamic> json) {
    return PictogramSet(
      id: id,
      name: json['name'] as String,
      userId: json['userId'] as String,
      pictograms: (json['pictograms'] as List<dynamic>?)
              ?.map((p) => Pictogram.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isAutoSaved: json['isAutoSaved'] as bool? ?? false,
    );
  }

  /// Get the number of steps/pictograms
  int get stepCount => pictograms.length;
}
