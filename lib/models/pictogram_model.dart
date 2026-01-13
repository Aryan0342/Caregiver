/// Model representing an ARASAAC pictogram
class Pictogram {
  final int id;
  final String keyword;
  final String category;
  final String imageUrl;
  final String? description;
  final bool isSelected;

  const Pictogram({
    required this.id,
    required this.keyword,
    required this.category,
    required this.imageUrl,
    this.description,
    this.isSelected = false,
  });

  /// Create a copy with updated selection state
  Pictogram copyWith({
    int? id,
    String? keyword,
    String? category,
    String? imageUrl,
    String? description,
    bool? isSelected,
  }) {
    return Pictogram(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'isSelected': isSelected,
    };
  }

  /// Create from JSON
  factory Pictogram.fromJson(Map<String, dynamic> json) {
    return Pictogram(
      id: json['id'] as int,
      keyword: json['keyword'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pictogram && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Pictogram categories
enum PictogramCategory {
  dagelijks('Dagelijks', 'daily'),
  eten('Eten', 'food'),
  verzorging('Verzorging', 'care'),
  gevoelens('Gevoelens', 'emotions');

  final String displayName;
  final String searchTerm;

  const PictogramCategory(this.displayName, this.searchTerm);
}
