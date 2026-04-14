/// Model representing a client managed by a caregiver.
class ClientProfile {
  final String id;
  final String caregiverId;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClientProfile({
    required this.id,
    required this.caregiverId,
    required this.name,
    this.phoneNumber,
    this.email,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  ClientProfile copyWith({
    String? id,
    String? caregiverId,
    String? name,
    String? phoneNumber,
    String? email,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caregiverId': caregiverId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ClientProfile.fromJson(String id, Map<String, dynamic> json) {
    return ClientProfile(
      id: id,
      caregiverId: (json['caregiverId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
