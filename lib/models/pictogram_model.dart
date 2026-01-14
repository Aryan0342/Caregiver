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

/// Pictogram categories - Based on ARASAAC's actual category structure
enum PictogramCategory {
  // Core ARASAAC categories
  eten('eten', 'feeding', 'voeding eten voedsel'),
  vrijetijd('vrijetijd', 'leisure', 'vrijetijd hobby sport spel'),
  plaats('plaats', 'place', 'plaats locatie gebouw'),
  levendWezen('levendWezen', 'living being', 'dier mens persoon'),
  onderwijs('onderwijs', 'education', 'onderwijs school leren'),
  tijd('tijd', 'time', 'tijd uur dag week maand'),
  diversen('diversen', 'miscellaneous', 'diversen overig'),
  beweging('beweging', 'movement', 'beweging lopen rennen'),
  religie('religie', 'religion', 'religie geloof'),
  werk('werk', 'work', 'werk baan beroep'),
  communicatie('communicatie', 'communication', 'communicatie praten bellen'),
  document('document', 'document', 'document papier brief'),
  kennis('kennis', 'knowledge', 'kennis informatie'),
  object('object', 'object', 'object voorwerp ding'),
  // Additional useful categories
  gevoelens('gevoelens', 'emotions', 'gevoel emotie'),
  gezondheid('gezondheid', 'health', 'gezondheid medicijn dokter'),
  lichaam('lichaam', 'body', 'lichaam lichaamsdeel');

  final String key; // Use key instead of hardcoded displayName
  final String searchTerm; // English term for API
  final String searchKeywords; // Dutch keywords for better search results

  const PictogramCategory(this.key, this.searchTerm, this.searchKeywords);
  
  // Keep displayName for backward compatibility, but it should use translations
  @Deprecated('Use getCategoryDisplayName with AppLocalizations instead')
  String get displayName {
    switch (this) {
      case PictogramCategory.eten:
        return 'Voeding';
      case PictogramCategory.vrijetijd:
        return 'Vrijetijd';
      case PictogramCategory.plaats:
        return 'Plaats';
      case PictogramCategory.levendWezen:
        return 'Levend wezen';
      case PictogramCategory.onderwijs:
        return 'Onderwijs';
      case PictogramCategory.tijd:
        return 'Tijd';
      case PictogramCategory.diversen:
        return 'Diversen';
      case PictogramCategory.beweging:
        return 'Beweging';
      case PictogramCategory.religie:
        return 'Religie';
      case PictogramCategory.werk:
        return 'Werk';
      case PictogramCategory.communicatie:
        return 'Communicatie';
      case PictogramCategory.document:
        return 'Document';
      case PictogramCategory.kennis:
        return 'Kennis';
      case PictogramCategory.object:
        return 'Object';
      case PictogramCategory.gevoelens:
        return 'Gevoelens';
      case PictogramCategory.gezondheid:
        return 'Gezondheid';
      case PictogramCategory.lichaam:
        return 'Lichaam';
    }
  }
}
