import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/pictogram_model.dart';

/// Service for fetching and caching ARASAAC pictograms
class ArasaacService {
  static const String _baseUrl = 'https://api.arasaac.org/api';
  static const String _imageBaseUrl = 'https://static.arasaac.org/pictograms';
  // ARASAAC image URL format: https://static.arasaac.org/pictograms/{id}/{id}_5000.png
  
  // Cache directory
  Directory? _cacheDir;

  /// Initialize cache directory
  Future<void> _initCache() async {
    if (_cacheDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, 'pictogram_cache'));
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    }
  }

  /// Get cache file path for a pictogram
  Future<String> _getCachePath(int pictogramId) async {
    await _initCache();
    return path.join(_cacheDir!.path, '$pictogramId.png');
  }

  /// Check if pictogram is cached locally
  Future<bool> isCached(int pictogramId) async {
    final cachePath = await _getCachePath(pictogramId);
    return File(cachePath).existsSync();
  }

  /// Get cached image file
  Future<File?> getCachedImage(int pictogramId) async {
    final cachePath = await _getCachePath(pictogramId);
    final file = File(cachePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Cache an image locally
  Future<void> _cacheImage(int pictogramId, List<int> imageData) async {
    final cachePath = await _getCachePath(pictogramId);
    final file = File(cachePath);
    await file.writeAsBytes(imageData);
  }

  /// Search pictograms by keyword/category
  Future<List<Pictogram>> searchPictograms({
    required PictogramCategory category,
    String? keyword,
    int limit = 50,
  }) async {
    try {
      // Build search query - ARASAAC uses URL encoding
      final searchTerms = [category.searchTerm];
      if (keyword != null && keyword.isNotEmpty) {
        searchTerms.add(keyword.toLowerCase());
      }
      
      final query = Uri.encodeComponent(searchTerms.join(' '));
      
      // ARASAAC API endpoint for searching (Dutch language)
      final url = Uri.parse('$_baseUrl/pictograms/nl/search/$query');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isEmpty) {
          // If no results, return sample pictograms
          return _getSamplePictograms(category);
        }
        
        // Limit results
        final limitedData = data.take(limit).toList();
        
        return limitedData.map((item) {
          final id = item['_id'] as int;
          // Get keyword from Dutch keywords array
          final keywords = item['keywords'] as List<dynamic>?;
          final dutchKeyword = keywords?.firstWhere(
            (k) => k['keyword'] != null,
            orElse: () => {'keyword': 'Unknown'},
          )?['keyword'] as String? ?? 'Unknown';
          
          return Pictogram(
            id: id,
            keyword: dutchKeyword,
            category: category.displayName,
            imageUrl: getStaticImageUrl(id), // Use static URL format
            description: keywords?.first?['meaning'] as String?,
          );
        }).toList();
      } else {
        // Fallback: return sample pictograms if API fails
        return _getSamplePictograms(category);
      }
    } catch (e) {
      // On error, return sample pictograms
      return _getSamplePictograms(category);
    }
  }

  /// Get sample pictograms for a category (fallback)
  /// Using common ARASAAC pictogram IDs - these are example IDs
  /// In production, these should be replaced with actual ARASAAC IDs from the API
  List<Pictogram> _getSamplePictograms(PictogramCategory category) {
    // Common ARASAAC pictogram IDs (these are examples - replace with real IDs from API)
    final Map<PictogramCategory, List<Map<String, dynamic>>> samples = {
      PictogramCategory.dagelijks: [
        {'id': 1, 'keyword': 'Wakker worden'}, // Wake up
        {'id': 2, 'keyword': 'Aankleden'}, // Get dressed
        {'id': 3, 'keyword': 'Ontbijten'}, // Breakfast
        {'id': 4, 'keyword': 'Tanden poetsen'}, // Brush teeth
        {'id': 5, 'keyword': 'Naar school'}, // School
      ],
      PictogramCategory.eten: [
        {'id': 100, 'keyword': 'Brood'}, // Bread
        {'id': 101, 'keyword': 'Melk'}, // Milk
        {'id': 102, 'keyword': 'Fruit'}, // Fruit
        {'id': 103, 'keyword': 'Groente'}, // Vegetables
        {'id': 104, 'keyword': 'Water'}, // Water
      ],
      PictogramCategory.verzorging: [
        {'id': 200, 'keyword': 'Wassen'}, // Washing
        {'id': 201, 'keyword': 'Douchen'}, // Shower
        {'id': 202, 'keyword': 'Handen wassen'}, // Wash hands
        {'id': 203, 'keyword': 'Haar kammen'}, // Comb hair
        {'id': 204, 'keyword': 'Medicijn'}, // Medicine
      ],
      PictogramCategory.gevoelens: [
        {'id': 300, 'keyword': 'Blij'}, // Happy
        {'id': 301, 'keyword': 'Verdrietig'}, // Sad
        {'id': 302, 'keyword': 'Boos'}, // Angry
        {'id': 303, 'keyword': 'Bang'}, // Afraid
        {'id': 304, 'keyword': 'Vermoeid'}, // Tired
      ],
    };

    final categorySamples = samples[category] ?? [];
    
    return categorySamples.map((sample) {
      final id = sample['id'] as int;
      return Pictogram(
        id: id,
        keyword: sample['keyword'] as String,
        category: category.displayName,
        imageUrl: '$_baseUrl/pictograms/$id?download=false&url=true',
      );
    }).toList();
  }

  /// Download and cache a pictogram image
  Future<File?> downloadAndCachePictogram(int pictogramId) async {
    try {
      // Check if already cached
      final cached = await getCachedImage(pictogramId);
      if (cached != null) {
        return cached;
      }

      // Download image
      final imageUrl = '$_imageBaseUrl/$pictogramId/${pictogramId}_5000.png';
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Cache the image
        await _cacheImage(pictogramId, response.bodyBytes);
        return await getCachedImage(pictogramId);
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get image URL for a pictogram (for network display)
  /// ARASAAC API endpoint that returns the image URL
  String getImageUrl(int pictogramId) {
    // Use ARASAAC API endpoint which returns the image URL
    // This is more reliable than constructing the URL manually
    return '$_baseUrl/pictograms/$pictogramId?download=false&url=true';
  }
  
  /// Get direct static image URL (fallback)
  /// ARASAAC static URL format: https://static.arasaac.org/pictograms/{id}/{id}_5000.png
  String getStaticImageUrl(int pictogramId) {
    // Direct static URL format - this is the most reliable format
    // Format: https://static.arasaac.org/pictograms/{id}/{id}_5000.png
    return '$_imageBaseUrl/$pictogramId/${pictogramId}_5000.png';
  }
  
  /// Try to get image URL with alternative formats
  List<String> getImageUrlAlternatives(int pictogramId) {
    return [
      '$_imageBaseUrl/$pictogramId/${pictogramId}_5000.png', // Standard format
      '$_imageBaseUrl/$pictogramId/${pictogramId}.png', // Without size suffix
      '$_baseUrl/pictograms/$pictogramId?download=false&url=true', // API endpoint
    ];
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _initCache();
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    await _initCache();
    if (_cacheDir == null || !await _cacheDir!.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
