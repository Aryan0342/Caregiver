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
      // Build search query
      final searchTerms = [category.searchTerm];
      if (keyword != null && keyword.isNotEmpty) {
        searchTerms.add(keyword.toLowerCase());
      }
      
      final query = searchTerms.join(' ');
      
      // ARASAAC API endpoint for searching
      final url = Uri.parse('$_baseUrl/pictograms/nl/search/$query');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Limit results
        final limitedData = data.take(limit).toList();
        
        return limitedData.map((item) {
          final id = item['_id'] as int;
          final keyword = item['keywords']?[0]?['keyword'] as String? ?? 
                         item['keywords']?[0]?['keyword'] as String? ?? 
                         'Unknown';
          
          // Build image URL
          final imageUrl = '$_imageBaseUrl/$id/${id}_5000.png';
          
          return Pictogram(
            id: id,
            keyword: keyword,
            category: category.displayName,
            imageUrl: imageUrl,
            description: item['keywords']?[0]?['meaning'] as String?,
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
  List<Pictogram> _getSamplePictograms(PictogramCategory category) {
    // Sample ARASAAC pictogram IDs for each category
    final Map<PictogramCategory, List<Map<String, dynamic>>> samples = {
      PictogramCategory.dagelijks: [
        {'id': 1, 'keyword': 'Wakker worden', 'term': 'wake'},
        {'id': 2, 'keyword': 'Aankleden', 'term': 'dress'},
        {'id': 3, 'keyword': 'Ontbijten', 'term': 'breakfast'},
        {'id': 4, 'keyword': 'Tanden poetsen', 'term': 'brush'},
        {'id': 5, 'keyword': 'Naar school', 'term': 'school'},
      ],
      PictogramCategory.eten: [
        {'id': 100, 'keyword': 'Brood', 'term': 'bread'},
        {'id': 101, 'keyword': 'Melk', 'term': 'milk'},
        {'id': 102, 'keyword': 'Fruit', 'term': 'fruit'},
        {'id': 103, 'keyword': 'Groente', 'term': 'vegetable'},
        {'id': 104, 'keyword': 'Water', 'term': 'water'},
      ],
      PictogramCategory.verzorging: [
        {'id': 200, 'keyword': 'Wassen', 'term': 'wash'},
        {'id': 201, 'keyword': 'Douchen', 'term': 'shower'},
        {'id': 202, 'keyword': 'Handen wassen', 'term': 'hand'},
        {'id': 203, 'keyword': 'Haar kammen', 'term': 'comb'},
        {'id': 204, 'keyword': 'Medicijn', 'term': 'medicine'},
      ],
      PictogramCategory.gevoelens: [
        {'id': 300, 'keyword': 'Blij', 'term': 'happy'},
        {'id': 301, 'keyword': 'Verdrietig', 'term': 'sad'},
        {'id': 302, 'keyword': 'Boos', 'term': 'angry'},
        {'id': 303, 'keyword': 'Bang', 'term': 'afraid'},
        {'id': 304, 'keyword': 'Vermoeid', 'term': 'tired'},
      ],
    };

    final categorySamples = samples[category] ?? [];
    
    return categorySamples.map((sample) {
      final id = sample['id'] as int;
      return Pictogram(
        id: id,
        keyword: sample['keyword'] as String,
        category: category.displayName,
        imageUrl: '$_imageBaseUrl/$id/${id}_5000.png',
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
  String getImageUrl(int pictogramId) {
    return '$_imageBaseUrl/$pictogramId/${pictogramId}_5000.png';
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
