import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/pictogram_model.dart';
import 'custom_pictogram_service.dart';

/// Service for fetching and caching ARASAAC pictograms.
/// 
/// ARASAAC (Aragonese Portal of Augmentative and Alternative Communication)
/// provides a free collection of pictograms for communication support.
/// 
/// This service handles:
/// - Searching pictograms by category or keyword (with multi-keyword support)
/// - Generating image URLs for ARASAAC pictograms
/// - Caching pictogram images locally for offline use
/// - Managing cache operations (clear, size calculation)
/// 
  /// All operations are Android-compatible and follow Flutter best practices.
class ArasaacService {
  /// Service for fetching custom pictograms from Firestore
  final CustomPictogramService _customPictogramService = CustomPictogramService();

  // ============================================================================
  // Constants
  // ============================================================================
  
  /// ARASAAC API base URL for search operations
  static const String _baseUrl = 'https://api.arasaac.org/api';
  
  /// ARASAAC static image base URL
  /// Format: https://static.arasaac.org/pictograms/{id}/{id}_{size}.png
  static const String _imageBaseUrl = 'https://static.arasaac.org/pictograms';
  
  /// Default timeout for HTTP requests (10 seconds)
  static const Duration _requestTimeout = Duration(seconds: 10);
  
  /// Default search result limit per category
  static const int _defaultLimit = 100;
  
  /// Maximum number of API calls per category search (safety limit)
  /// Set high enough to process all search terms
  static const int _maxApiCallsPerCategory = 100; // Allow processing all search terms
  
  /// Cache directory name within app documents
  static const String _cacheMetadataFile = 'cache_metadata.json';
  static const String _cacheDirectoryName = 'pictogram_cache';
  
  /// Default language code for ARASAAC API (Dutch)
  static const String _defaultLanguage = 'nl';
  
  /// Language code used for category searches (English for better results)
  static const String _categorySearchLanguage = 'en';

  // ============================================================================
  // Language Configuration
  // ============================================================================
  
  /// Current language code for ARASAAC API searches.
  /// 
  /// Supported language codes: 'nl' (Dutch), 'en' (English), 'es' (Spanish), etc.
  /// Defaults to 'nl' (Dutch) for backward compatibility.
  /// 
  /// This language is used for:
  /// - Keyword search API endpoints
  /// - Keyword extraction preference (for display)
  /// 
  /// Note: Category searches always use English ('en') internally for better results,
  /// but keyword extraction still prefers the UI language.
  String _language = _defaultLanguage;

  /// Get the current language code.
  /// 
  /// Returns the current language code being used for keyword searches and display.
  String get language => _language;

  /// Set the language code for ARASAAC API searches.
  /// 
  /// [languageCode] - The language code (e.g., 'nl', 'en', 'es')
  /// Must be a valid ARASAAC language code.
  /// 
  /// Note: This affects keyword searches and display language, but category
  /// searches will still use English internally for optimal results.
  /// 
  /// Example:
  /// ```dart
  /// service.setLanguage('en'); // Switch to English
  /// ```
  void setLanguage(String languageCode) {
    _language = languageCode.toLowerCase().trim();
  }

  // ============================================================================
  // Cache Management
  // ============================================================================
  
  /// Cache directory instance (lazy-initialized)
  Directory? _cacheDir;

  /// Get the cache directory (public method for accessing cache).
  /// 
  /// Returns the cache directory if initialized, null otherwise.
  Future<Directory?> getCacheDirectory() async {
    await _initCache();
    return _cacheDir;
  }

  /// Initialize cache directory if not already initialized.
  /// 
  /// Creates the cache directory in the app's documents directory.
  /// This is called automatically when cache operations are needed.
  Future<void> _initCache() async {
    if (_cacheDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, _cacheDirectoryName));
      
      // Create directory if it doesn't exist
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    }
  }

  /// Get the cache file path for a specific pictogram ID.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns the full path to the cached image file
  Future<String> _getCachePath(int pictogramId) async {
    await _initCache();
    return path.join(_cacheDir!.path, '$pictogramId.png');
  }

  /// Check if a pictogram is cached locally.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID to check
  /// Returns true if the pictogram is cached, false otherwise
  Future<bool> isCached(int pictogramId) async {
    final cachePath = await _getCachePath(pictogramId);
    return File(cachePath).existsSync();
  }

  /// Get the cached image file for a pictogram.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns the cached File if it exists, null otherwise
  Future<File?> getCachedImage(int pictogramId) async {
    final cachePath = await _getCachePath(pictogramId);
    final file = File(cachePath);
    
    if (await file.exists()) {
      return file;
    }
    
    return null;
  }

  /// Get metadata file path for cache
  Future<String> _getMetadataPath() async {
    await _initCache();
    return path.join(_cacheDir!.path, _cacheMetadataFile);
  }

  /// Load cache metadata (pictogram ID -> category mapping)
  Future<Map<int, String>> _loadCacheMetadata() async {
    try {
      final metadataPath = await _getMetadataPath();
      final file = File(metadataPath);
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        // Handle empty file
        if (content.isEmpty) {
          return {};
        }
        
        // Fix corrupted JSON (remove extra closing braces)
        String cleanedContent = content;
        // Count opening and closing braces
        final openBraces = cleanedContent.split('{').length - 1;
        final closeBraces = cleanedContent.split('}').length - 1;
        
        // If there are extra closing braces, remove them
        if (closeBraces > openBraces) {
          final extraBraces = closeBraces - openBraces;
          // Remove extra closing braces from the end
          for (int i = 0; i < extraBraces; i++) {
            final lastBraceIndex = cleanedContent.lastIndexOf('}');
            if (lastBraceIndex != -1) {
              cleanedContent = cleanedContent.substring(0, lastBraceIndex) + 
                              cleanedContent.substring(lastBraceIndex + 1);
            }
          }
        }
        
        final Map<String, dynamic> data = json.decode(cleanedContent);
        return data.map((key, value) => MapEntry(int.parse(key), value as String));
      }
    } catch (e) {
      // If JSON is still corrupted, try to fix it by recreating the file
      if (kDebugMode) {
        debugPrint('Error loading cache metadata (will recreate): $e');
      }
      // Delete corrupted file so it can be recreated
      try {
        final metadataPath = await _getMetadataPath();
        final file = File(metadataPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore deletion errors
      }
    }
    return {};
  }

  /// Save cache metadata (pictogram ID -> category mapping)
  Future<void> _saveCacheMetadata(Map<int, String> metadata) async {
    try {
      final metadataPath = await _getMetadataPath();
      final file = File(metadataPath);
      final data = metadata.map((key, value) => MapEntry(key.toString(), value));
      await file.writeAsString(json.encode(data));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving cache metadata: $e');
      }
    }
  }

  /// Cache an image locally by writing it to disk.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// [imageData] - The image bytes to cache
  /// [category] - Optional category for metadata storage
  Future<void> _cacheImage(int pictogramId, List<int> imageData, {String? category}) async {
    try {
      await _initCache(); // Ensure cache directory exists
      final cachePath = await _getCachePath(pictogramId);
      final file = File(cachePath);
      
      if (kDebugMode) {
        debugPrint('Caching pictogram $pictogramId to: $cachePath (${imageData.length} bytes)');
      }
      
      await file.writeAsBytes(imageData);
      
      // Save category metadata if provided
      if (category != null) {
        final metadata = await _loadCacheMetadata();
        metadata[pictogramId] = category;
        await _saveCacheMetadata(metadata);
      }
      
      // Verify the file was written
      if (await file.exists()) {
        final fileSize = await file.length();
        if (kDebugMode) {
          debugPrint('Successfully wrote pictogram $pictogramId: $fileSize bytes');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Warning: File was written but does not exist: $cachePath');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in _cacheImage for pictogram $pictogramId: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow; // Re-throw to be caught by caller
    }
  }

  /// Download and cache a pictogram image from ARASAAC.
  /// 
  /// This method:
  /// 1. Checks if the image is already cached (returns cached file if found)
  /// 2. Downloads the image from ARASAAC (5000px quality)
  /// 3. Caches the image locally for future use
  /// 
  /// Fails silently if offline or on any error - never throws exceptions.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID to download
  /// Returns the cached File if successful, null on error or offline
  /// Clear cache for a specific category
  /// 
  /// [category] - The category key to clear cache for
  Future<void> clearCacheForCategory(String category) async {
    try {
      final metadata = await _loadCacheMetadata();
      final idsToRemove = <int>[];
      
      // Find all pictogram IDs for this category
      metadata.forEach((id, cat) {
        if (cat == category) {
          idsToRemove.add(id);
        }
      });
      
      // Delete image files and remove from metadata
      for (final id in idsToRemove) {
        try {
          final cachePath = await _getCachePath(id);
          final file = File(cachePath);
          if (await file.exists()) {
            await file.delete();
          }
          metadata.remove(id);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error deleting cached pictogram $id: $e');
          }
        }
      }
      
      // Save updated metadata
      await _saveCacheMetadata(metadata);
      
      if (kDebugMode) {
        debugPrint('Cleared ${idsToRemove.length} cached pictograms for category $category');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing cache for category $category: $e');
      }
    }
  }

  /// Download and cache a pictogram image from ARASAAC at a specific size.
  /// 
  /// This method:
  /// 1. Checks if the image is already cached (returns cached file if found)
  /// 2. Downloads the image from ARASAAC, trying multiple sizes as fallback
  /// 3. Caches the image locally for future use
  /// 
  /// Fails silently if offline or on any error - never throws exceptions.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID to download
  /// [size] - The preferred image size in pixels (default: 500 for smaller files)
  /// [category] - Optional category for metadata storage
  /// Returns the cached File if successful, null on error or offline
  Future<File?> downloadAndCachePictogramAtSize(int pictogramId, {int size = 500, String? category}) async {
    try {
      // Check if already cached - if cached and category matches, return cached file
      final cached = await getCachedImage(pictogramId);
      if (cached != null) {
        // If category is provided, check if metadata matches
        if (category != null) {
          final metadata = await _loadCacheMetadata();
          final cachedCategory = metadata[pictogramId];
          // If category matches, return cached file (skip download)
          if (cachedCategory == category) {
            if (kDebugMode) {
              debugPrint('Pictogram $pictogramId already cached with correct category');
            }
            return cached;
          }
          // Category doesn't match - update it in metadata
          metadata[pictogramId] = category;
          await _saveCacheMetadata(metadata);
          return cached;
        } else {
          // No category specified - return cached file
          if (kDebugMode) {
            debugPrint('Pictogram $pictogramId already cached');
          }
          return cached;
        }
      }

      // Not cached - download and cache
      // Try sizes 500px and below only (more commonly available and smaller file sizes)
      // ARASAAC may not have all sizes for all pictograms
      final sizesToTry = [size <= 500 ? size : 500, 500];
      // Remove duplicates while preserving order
      final uniqueSizes = <int>[];
      for (final s in sizesToTry) {
        if (s <= 500 && !uniqueSizes.contains(s)) {
          uniqueSizes.add(s);
        }
      }
      
      // If no valid sizes (all were > 500), default to 500
      if (uniqueSizes.isEmpty) {
        uniqueSizes.add(500);
      }

      for (final trySize in uniqueSizes) {
        try {
          // Download image at this size
          final imageUrl = getStaticImageUrlWithSize(pictogramId, size: trySize);
          if (kDebugMode) {
            debugPrint('Downloading pictogram $pictogramId from: $imageUrl');
          }
          
          final response = await http.get(Uri.parse(imageUrl)).timeout(
            _requestTimeout,
            onTimeout: () {
              if (kDebugMode) {
                debugPrint('Timeout downloading pictogram $pictogramId at size $trySize');
              }
              throw Exception('Request timeout');
            },
          );

          if (kDebugMode) {
            debugPrint('Response status for pictogram $pictogramId (size $trySize): ${response.statusCode}, body length: ${response.bodyBytes.length}');
          }

          if (response.statusCode == 200) {
            if (response.bodyBytes.isEmpty) {
              if (kDebugMode) {
                debugPrint('Empty response body for pictogram $pictogramId at size $trySize');
              }
              continue; // Try next size
            }
            
            // Cache the image
                  try {
                    await _cacheImage(pictogramId, response.bodyBytes, category: category);
                    if (kDebugMode) {
                      debugPrint('Successfully cached pictogram $pictogramId at size $trySize');
                    }
              
              final cachedFile = await getCachedImage(pictogramId);
              if (cachedFile == null) {
                if (kDebugMode) {
                  debugPrint('Warning: Pictogram $pictogramId was cached but getCachedImage returned null');
                }
              }
              return cachedFile;
            } catch (cacheError) {
              if (kDebugMode) {
                debugPrint('Error caching pictogram $pictogramId: $cacheError');
              }
              continue; // Try next size
            }
          } else if (response.statusCode == 404) {
            // This size doesn't exist, try next size
            if (kDebugMode) {
              debugPrint('Size $trySize not available for pictogram $pictogramId (404), trying next size...');
            }
            continue;
          } else {
            if (kDebugMode) {
              debugPrint('Failed to download pictogram $pictogramId at size $trySize: HTTP ${response.statusCode}');
            }
            continue; // Try next size
          }
        } on SocketException catch (e) {
          // Offline - stop trying
          if (kDebugMode) {
            debugPrint('SocketException downloading pictogram $pictogramId: $e');
          }
          return null;
        } on TimeoutException catch (e) {
          if (kDebugMode) {
            debugPrint('TimeoutException downloading pictogram $pictogramId at size $trySize: $e');
          }
          continue; // Try next size
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error downloading pictogram $pictogramId at size $trySize: $e');
          }
          continue; // Try next size
        }
      }
      
      // All sizes failed
      if (kDebugMode) {
        debugPrint('Failed to download pictogram $pictogramId at any available size');
      }
      return null;
    } on SocketException catch (e) {
      // Offline - fail silently
      if (kDebugMode) {
        debugPrint('SocketException downloading pictogram $pictogramId: $e');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('TimeoutException downloading pictogram $pictogramId: $e');
      }
    } catch (e, stackTrace) {
      // Any other error - log with stack trace
      if (kDebugMode) {
        debugPrint('Error downloading pictogram $pictogramId: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    return null;
  }

  /// Download and cache a pictogram image from ARASAAC (using size 500px).
  /// 
  /// Convenience method that calls downloadAndCachePictogramAtSize with size=500.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID to download
  /// [category] - Optional category for metadata storage
  /// Returns the cached File if successful, null on error or offline
  Future<File?> downloadAndCachePictogram(int pictogramId, {String? category}) async {
    return await downloadAndCachePictogramAtSize(pictogramId, size: 500, category: category);
  }

  /// Get cached pictograms by their IDs, optionally filtered by category.
  /// 
  /// This method is useful for offline scenarios where you have a list of
  /// pictogram IDs and want to retrieve only those that are cached locally.
  /// 
  /// Returns Pictogram objects for IDs that are cached. IDs that are not
  /// cached are silently skipped (not included in the result).
  /// 
  /// For offline use, the imageUrl will be a file:// path to the local cached file.
  /// 
  /// [ids] - List of ARASAAC pictogram IDs to retrieve (optional, if null returns all cached)
  /// [category] - Optional category filter (only returns pictograms from this category)
  /// 
  /// Returns a list of Pictogram objects for cached IDs only
  Future<List<Pictogram>> getCachedPictograms({List<int>? ids, String? category}) async {
    final cachedPictograms = <Pictogram>[];
    final metadata = await _loadCacheMetadata();
    
    if (kDebugMode) {
      debugPrint('getCachedPictograms: metadata has ${metadata.length} entries, filtering by category: $category');
    }
    
    // If no IDs provided, get all cached IDs from directory
    List<int> idsToCheck = ids ?? [];
    if (idsToCheck.isEmpty) {
      try {
        final cacheDir = await getCacheDirectory();
        if (cacheDir != null && await cacheDir.exists()) {
          await for (final entity in cacheDir.list()) {
            if (entity is File) {
              final fileName = entity.path.split(Platform.pathSeparator).last;
              final match = RegExp(r'^(\d+)\.png$').firstMatch(fileName);
              if (match != null) {
                final id = int.tryParse(match.group(1)!);
                if (id != null) {
                  idsToCheck.add(id);
                }
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error listing cache directory: $e');
        }
      }
    }
    
    for (final id in idsToCheck) {
      try {
        // Check if this pictogram is cached
        final cachedFile = await getCachedImage(id);
        
        if (cachedFile != null) {
          // Get category from metadata
          final pictogramCategory = metadata[id] ?? 'cached';
          
          // Filter by category if specified
          // But be lenient: if metadata says 'cached' (old cache without category),
          // still include it in offline mode since we can't determine the actual category
          if (category != null && pictogramCategory != category) {
            // Only skip if we have a specific category stored that doesn't match
            // If it's 'cached' (no category metadata), include it anyway in offline mode
            if (pictogramCategory != 'cached') {
              if (kDebugMode) {
                debugPrint('Skipping pictogram $id: category mismatch (stored: $pictogramCategory, requested: $category)');
              }
              continue; // Has category metadata but doesn't match - skip
            }
            // If pictogramCategory is 'cached' (no metadata), include it anyway
            // This handles old cached pictograms that don't have category metadata
            if (kDebugMode) {
              debugPrint('Including pictogram $id with no category metadata (requested: $category)');
            }
          }
          
          if (kDebugMode && cachedPictograms.length < 5) {
            debugPrint('Adding cached pictogram $id with category: ${category ?? pictogramCategory}');
          }
          
          // Create a Pictogram object for the cached image
          cachedPictograms.add(Pictogram(
            id: id,
            keyword: 'Pictogram $id', // Default keyword since we don't store metadata
            category: category ?? pictogramCategory, // Use requested category or stored category
            imageUrl: cachedFile.path, // Use local file path for offline access
          ));
        }
      } catch (e) {
        // Skip this ID on error - fail silently
        if (kDebugMode) {
          debugPrint('Error checking cache for pictogram $id: $e');
        }
        continue;
      }
    }
    
    if (kDebugMode) {
      debugPrint('getCachedPictograms: Returning ${cachedPictograms.length} cached pictograms (checked ${idsToCheck.length} IDs)');
    }
    
    return cachedPictograms;
  }

  /// Clear all cached pictogram images.
  /// 
  /// Deletes the entire cache directory and recreates it.
  /// Useful for freeing up storage space or resetting the cache.
  Future<void> clearCache() async {
    await _initCache();
    
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }

  /// Get the total size of the cache directory in bytes.
  /// 
  /// Iterates through all files in the cache directory and sums their sizes.
  /// Returns 0 if cache directory doesn't exist or is empty.
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

  // ============================================================================
  // Search Operations
  // ============================================================================

  /// Check if a pictogram is relevant for a category based on its keyword.
  /// 
  /// Filters out irrelevant results that match search terms but aren't actually
  /// related to the category (e.g., "theater" matching "eat" search).
  /// 
  /// [pictogram] - The pictogram to check
  /// [category] - The category to check relevance for
  /// [searchTerm] - The search term that found this pictogram
  /// Returns true if the pictogram is relevant for the category
  bool _isRelevantForCategory(Pictogram pictogram, PictogramCategory category, String searchTerm) {
    final keyword = pictogram.keyword.toLowerCase();
    final term = searchTerm.toLowerCase();
    
    // If keyword contains the search term as a whole word (not substring), it's likely relevant
    // Use word boundaries to avoid matching "eat" in "theater" or "sweater"
    final wordBoundaryPattern = RegExp(r'\b' + RegExp.escape(term) + r'\b', caseSensitive: false);
    if (wordBoundaryPattern.hasMatch(keyword)) {
      return true;
    }
    
    // Category-specific relevance checks
    switch (category) {
      case PictogramCategory.eten:
        // Exclude words that contain "eat" but aren't about eating
        final irrelevantPatterns = [
          RegExp(r'\b(theater|sweater|defeat|treat|seat|heat|beat|meat|neat|great)\b', caseSensitive: false),
        ];
        for (final pattern in irrelevantPatterns) {
          if (pattern.hasMatch(keyword)) {
            // Check if it's actually about food/eating
            final foodKeywords = ['eten', 'voedsel', 'maaltijd', 'drinken', 'brood', 'fruit', 'groente', 'drink', 'food', 'meal'];
            final isFoodRelated = foodKeywords.any((food) => keyword.contains(food));
            if (!isFoodRelated) {
              return false; // Exclude irrelevant matches
            }
          }
        }
        // Include if keyword contains food-related terms
        final foodTerms = ['eten', 'drinken', 'voedsel', 'maaltijd', 'ontbijt', 'lunch', 'diner', 'brood', 'fruit', 'groente', 'drink', 'food', 'meal', 'eat', 'breakfast', 'dinner'];
        return foodTerms.any((food) => keyword.contains(food));
        
      default:
        // For other categories, if keyword contains the search term, it's likely relevant
        return keyword.contains(term);
    }
  }

  /// Get multiple search terms for a category to maximize results.
  /// 
  /// Each category has a primary search term and additional related terms
  /// that help find more relevant pictograms. This method returns a list
  /// of search terms to query separately and merge results.
  /// 
  /// [category] - The pictogram category
  /// Returns a list of search terms (English) for this category
  List<String> _getCategorySearchTerms(PictogramCategory category) {
    // Comprehensive keyword lists based on ARASAAC category structure
    switch (category) {
      case PictogramCategory.eten:
        // Feeding: Food (Animal-based, Plant-based, Processed, Ultra-processed), Beverage, Gastronomy, Traditional dish, Taste, Cookery
        return [
          'eten', 'drinken', 'voedsel', 'maaltijd', 'ontbijt', 'lunch', 'diner',
          'vlees', 'vis', 'zeevruchten', 'zuivel', 'ei', 'eiproduct',
          'fruit', 'groente', 'gedroogd fruit', 'peulvrucht', 'graan', 'kruiden', 'aromatische kruiden',
          'vleeswaren', 'dessert', 'bakken', 'snoep', 'condiment',
          'drank', 'beverage', 'gastronomie', 'traditioneel gerecht', 'smaak', 'koken', 'kookkunst'
        ];
      case PictogramCategory.vrijetijd:
        // Leisure: Sport, Traditional game, Toy, Game, Show, Hobby, Outdoor activity, Entertainment facility
        return [
          'vrijetijd', 'hobby', 'sport', 'sportevenement', 'olympische spelen', 'sportmodaliteit',
          'sportregels', 'aangepaste sport', 'sportkleding', 'sportmateriaal', 'sportfaciliteit',
          'atleet', 'sportgroep', 'karate', 'schaatsen', 'duiken', 'basketbal', 'surfen',
          'fietsen', 'voetbal', 'zwemmen', 'schaken', 'paardrijden', 'lichamelijke oefening',
          'atletiek', 'gymnastiek', 'ritmische gymnastiek', 'acrobatische gymnastiek',
          'traditioneel spel', 'speelgoed', 'toy', 'spel', 'gokken', 'kaartspel', 'bordspel',
          'videogame', 'show', 'buitensport', 'strand', 'zwembad', 'berg', 'entertainment faciliteit'
        ];
      case PictogramCategory.plaats:
        // Place: Monument, Building, Facility, Urban area, Infrastructure, Workplace, Rural area
        return [
          'plaats', 'locatie', 'monument', 'gebouw', 'woongebouw', 'kamer', 'room',
          'commercieel gebouw', 'cultureel gebouw', 'horeca', 'religieus gebouw',
          'gebouwsfaciliteit', 'industrieel gebouw', 'onderwijsgebouw', 'medisch centrum',
          'gebouwskamer', 'openbaar gebouw', 'dienstgebouw', 'faciliteit', 'recreatiefaciliteit',
          'speeltuin', 'recyclingcentrum', 'stedelijk gebied', 'straatmeubilair',
          'infrastructuur', 'werkplek', 'landelijk gebied'
        ];
      case PictogramCategory.onderwijs:
        // Education: Teaching activity, Subject, Educational institution, Educational task, Educational material, etc.
        return [
          'onderwijs', 'school', 'leren', 'leraar', 'leerling', 'klas', 'les',
          'onderwijsactiviteit', 'vak', 'onderwijsinstelling', 'onderwijstaak',
          'onderwijsmateriaal', 'onderwijsapparatuur', 'onderwijsruimte',
          'onderwijsorganisatie', 'onderwijsinstelling', 'speciaal onderwijs',
          'onderwijspersoneel', 'onderwijsdocumentatie', 'studenten', 'onderwijsmethodologie'
        ];
      case PictogramCategory.tijd:
        // Time: Chronological time (Event, Calendar, Unit of time), Chronological instrument
        return [
          'tijd', 'uur', 'dag', 'week', 'maand', 'jaar', 'moment',
          'chronologische tijd', 'evenement', 'populair evenement', 'halloween', 'carnaval',
          'nieuwjaar', 'fiestas del pilar', 'populair festival', 'kerstmis', 'paasweek',
          'religieus evenement', 'sociaal evenement', 'verjaardag', 'bruiloft', 'dood',
          'oorlog', 'kalender', 'seizoen', 'dagtijd', 'tijdeenheid', 'daguren',
          'chronologisch instrument'
        ];
      case PictogramCategory.diversen:
        // Miscellaneous: COVID-19, Categorization, International organization, Seasons, Aragon, Orofacial praxis
        return [
          'diversen', 'overig', 'anders', 'miscellaneous',
          'covid-19', 'categorisatie', 'internationale organisatie', 'seizoenen',
          'winter', 'zomer', 'herfst', 'lente', 'aragon', 'huesca', 'teruel', 'zaragoza',
          'orofaciale praxis'
        ];
      case PictogramCategory.beweging:
        // Movement: Traffic, Route, Traffic accident
        return [
          'beweging', 'lopen', 'rennen', 'gaan', 'reizen', 'verplaatsen',
          'verkeer', 'verkeersveiligheid', 'verkeerslicht', 'vervoermiddel',
          'watertransport', 'luchttransport', 'landtransport', 'voertuigonderdeel',
          'route', 'verkeersongeval'
        ];
      case PictogramCategory.religie:
        // Religion: Christianity, Islamism, Judaism, Buddhism, Hinduism, Religious object, Religious place, etc.
        return [
          'religie', 'geloof', 'kerk', 'bidden', 'aanbidden',
          'christendom', 'islam', 'jodendom', 'boeddhisme', 'hindoeïsme',
          'religieus object', 'religieuze plaats', 'religieus persoon',
          'religieus karakter', 'religieuze handeling'
        ];
      case PictogramCategory.werk:
        // Work: Economic sector (Primary, Secondary, Tertiary), Professional services, Professional, etc.
        return [
          'werk', 'baan', 'beroep', 'kantoor', 'carrière', 'arbeid',
          'economische sector', 'primaire sector', 'veeteelt', 'visserij', 'landbouw',
          'mijnbouw', 'bosbouw', 'bijenteelt', 'tuinieren', 'jacht',
          'secundaire sector', 'industrie', 'energie', 'bouw', 'ambacht', 'kledingindustrie', 'timmerman',
          'tertiaire sector', 'toerisme', 'financiële diensten', 'openbaar bestuur',
          'handel', 'horeca', 'veiligheid en defensie', 'telecommunicatie', 'cultuur',
          'professionele diensten', 'consultancy', 'afvalverwerking', 'persoonlijke diensten',
          'kapper', 'politieke vertegenwoordiging', 'verkiezing', 'recht en justitie',
          'juridische instelling', 'informatietechnologie', 'professional', 'onderwijsprofessional',
          'sanitair professional', 'kunstenaar', 'muzikant', 'uitvoerend kunstenaar', 'beeldend kunstenaar',
          'verkoper', 'werkgereedschap', 'werkmachine', 'werkplaats', 'werkkleding',
          'beschermingsuitrusting', 'werkongeval', 'werkorganisatie'
        ];
      case PictogramCategory.communicatie:
        // Communication: Augmentative communication, Communication system, Communication aid, AAC implementation, Language (Lexicon)
        return [
          'communicatie', 'praten', 'spreken', 'telefoon', 'bellen', 'bericht',
          'augmentatieve communicatie', 'communicatiesysteem', 'communicatiehulpmiddel',
          'aac implementatie', 'taal', 'lexicon', 'bijvoeglijk naamwoord',
          'kwalificerend bijvoeglijk naamwoord', 'vergelijkend bijvoeglijk naamwoord',
          'onbepaald bijvoeglijk naamwoord', 'telwoord', 'rangtelwoord', 'bezittelijk bijvoeglijk naamwoord',
          'overtreffende trap', 'demonym', 'aanwijzend bijvoeglijk naamwoord',
          'bijwoord', 'bijwoord van toevoeging', 'bijwoord van bevestiging',
          'bijwoord van graad', 'bijwoord van twijfel', 'bijwoord van uitsluiting',
          'bijwoord van plaats', 'bijwoord van wijze', 'bijwoord van ontkenning'
        ];
      case PictogramCategory.document:
        // Document: Medical documentation, Supporting document, Official document, etc.
        return [
          'document', 'papier', 'brief', 'bestand', 'formulier', 'briefje',
          'medische documentatie', 'ondersteunend document', 'officieel document',
          'onderwijsdocument', 'informatiedocument', 'gerechtelijk document',
          'handelsdocument', 'kernwoordenschat'
        ];
      case PictogramCategory.kennis:
        // Knowledge: Art, Science, Humanities, Core vocabulary
        return [
          'kennis', 'informatie', 'leren', 'begrijpen', 'weten',
          'kunst', 'wetenschap', 'geesteswetenschappen', 'kernwoordenschat'
        ];
      case PictogramCategory.object:
        // Object: Object property, Size, Texture, Pattern, Furniture, Appliance, etc.
        return [
          'object', 'voorwerp', 'ding', 'gereedschap', 'apparaat', 'uitrusting',
          'objecteigenschap', 'kleur', 'vorm', 'materiaal', 'afgeleid materiaal',
          'grondstof', 'dierlijk materiaal', 'mineraal materiaal', 'plantaardig materiaal',
          'fossiel materiaal', 'grootte', 'textuur', 'patroon', 'meubilair',
          'apparaat', 'massamedia apparaat', 'chronologisch apparaat', 'atmosferisch apparaat',
          'elektrisch apparaat', 'verlichting', 'muziekapparaat', 'schoonmaakproduct',
          'hygiëneproduct', 'huishouden', 'trousseau', 'bestek', 'gerei', 'servies',
          'mode', 'accessoires', 'sieraden', 'schoenen', 'kleding', 'kostuum', 'regionaal kostuum',
          'cosmetica', 'zintuiglijke stimulatiemateriaal', 'publicatie'
        ];
      case PictogramCategory.levendWezen:
        // Living being
        return [
          'dier', 'mens', 'persoon', 'huisdier', 'hond', 'kat', 'dieren',
          'levend wezen', 'dierlijk', 'mensen', 'persoonlijk'
        ];
      case PictogramCategory.gevoelens:
        // Emotions
        return [
          'gevoel', 'emotie', 'blij', 'verdrietig', 'boos', 'liefde', 'gelukkig',
          'gevoelens', 'emoties'
        ];
      case PictogramCategory.gezondheid:
        // Health
        return [
          'gezondheid', 'medicijn', 'dokter', 'ziekenhuis', 'medisch', 'geneeskunde',
          'gezondheidszorg', 'medicatie'
        ];
      case PictogramCategory.lichaam:
        // Body
        return [
          'lichaam', 'hoofd', 'hand', 'voet', 'oog', 'oor', 'mond', 'gezicht', 'lichaamsdeel',
          'lichaamsdelen'
        ];
    }
  }

  /// Search pictograms by category with optional keyword filter.
  /// 
  /// This method uses a multi-keyword search strategy:
  /// 1. Gets multiple search terms for the category
  /// 2. Searches each term separately using ARASAAC API (in English)
  /// 3. Merges all results and removes duplicates
  /// 4. Returns up to the target number of pictograms (40-80)
  /// 5. Falls back to generic categories only if very few results (0-2)
  /// 
  /// When offline, returns an empty list (no exceptions thrown).
  /// Use getCachedPictograms() to retrieve cached pictograms by ID.
  /// 
  /// [category] - The pictogram category to search
  /// [keyword] - Optional keyword to filter results (if provided, uses single search)
  /// [limit] - Maximum number of results to return (default: 100)
  /// 
  /// Returns a list of Pictogram objects matching the search criteria
  /// Returns empty list if offline or on error (never throws exceptions)
  Future<List<Pictogram>> searchPictograms({
    required PictogramCategory category,
    String? keyword,
    int limit = _defaultLimit,
    int offset = 0,
  }) async {
    // If a specific keyword is provided, use single search (backward compatibility)
    if (keyword != null && keyword.isNotEmpty) {
      return await _singleKeywordSearch(category, keyword, limit);
    }

    // Multi-keyword category search for maximum results
    try {
      final searchTerms = _getCategorySearchTerms(category);
      final mergedResults = <Pictogram>[];
      final seenIds = <int>{};
      int apiCallCount = 0;

      // Search each term separately and merge results
      // Process all search terms to get maximum results
      // Only limit if we have too many terms (safety check)
      final termsToProcess = searchTerms.length > 50 
          ? searchTerms.take(50).toList() 
          : searchTerms;

      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Using ${searchTerms.length} search terms, processing ${termsToProcess.length}');
      }
      
      for (final term in termsToProcess) {
        // Safety limit: don't exceed max API calls
        if (apiCallCount >= _maxApiCallsPerCategory) {
          if (kDebugMode) {
            debugPrint('Category search [${category.key}]: Reached API call limit ($_maxApiCallsPerCategory)');
          }
          break;
        }

        try {
          final encodedQuery = Uri.encodeComponent(term);
          // Search with Dutch language to get Dutch keywords in response
          // Using Dutch search terms for better relevance
          final url = _buildSearchUrl(encodedQuery, language: 'nl');
          
          final response = await http.get(url).timeout(
            _requestTimeout,
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

          apiCallCount++;

          if (response.statusCode == 200) {
            // Calculate how many results we still need for fast response
            final resultsNeeded = (offset + limit) - mergedResults.length;
            
            // Request only what we need per term for faster response
            // For initial load (offset=0, limit=18), request ~25 per term to get variety quickly
            // For subsequent loads, request more to ensure we have enough
            final resultsPerTerm = resultsNeeded > 0 
                ? (resultsNeeded * 1.5).round().clamp(25, 100) // Request 1.5x what we need, min 25, max 100
                : 100; // If we already have enough, still request 100 for variety
            
            final termResults = _parseSearchResponse(
              response.body,
              category,
              resultsPerTerm,
            );

            int addedFromTerm = 0;
            for (var pictogram in termResults) {
              // Early exit: if we already have enough results, stop processing this term
              if (mergedResults.length >= (offset + limit)) {
                break;
              }
              
              // Only add if not already seen (deduplicate)
              if (!seenIds.contains(pictogram.id)) {
                // Add all pictograms from search - no relevance filtering
                // The comprehensive keyword lists should already ensure relevance
                seenIds.add(pictogram.id);
                
                // Add pictogram without enhancement during search (will enhance later in batch)
                mergedResults.add(pictogram);
                addedFromTerm++;
              }
            }

            if (kDebugMode && addedFromTerm > 0) {
              debugPrint('Category search [${category.key}]: Term "$term" returned $addedFromTerm new pictograms (total: ${mergedResults.length})');
            }

            // Early exit: if we have enough results for pagination, return immediately
            // This provides fast initial response (only fetch what's needed)
            if (mergedResults.length >= (offset + limit)) {
              if (kDebugMode) {
                debugPrint('Category search [${category.key}]: Early exit - have ${mergedResults.length} results, need ${offset + limit}');
              }
              break; // Stop searching more terms, we have enough
            }
          }
        } on SocketException {
          // Offline - skip this term silently
          continue;
        } catch (e) {
          // Error on this term - skip and continue with next term
          if (kDebugMode) {
            debugPrint('Category search [${category.key}]: Error searching term "$term": $e');
          }
          continue;
        }
      }

      // Apply pagination: skip offset and take limit
      var finalResults = mergedResults.skip(offset).take(limit).toList();

      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Total merged results: ${finalResults.length} (from $apiCallCount API calls)');
      }

      // Only use fallback if we have very few results (0-2) to maintain category relevance
      if (finalResults.length <= 2) {
        final fallbackResults = await _tryFallbackSearches(category, limit, finalResults.length);
        
        // Only combine if we have very few original results
        if (fallbackResults.isNotEmpty && finalResults.length <= 2) {
          final combined = <Pictogram>[...finalResults];
          
          // Add fallback results up to the limit, avoiding duplicates
          for (var result in fallbackResults) {
            if (combined.length >= limit) break;
            if (!combined.any((p) => p.id == result.id)) {
              combined.add(result);
            }
          }
          
          if (kDebugMode && combined.length > finalResults.length) {
            debugPrint('Category search [${category.key}]: Added ${combined.length - finalResults.length} pictograms from fallback (original: ${finalResults.length})');
          }
          
          return combined;
        }
      }
      
      // Merge with custom pictograms for this category
      try {
        final customPictograms = await _customPictogramService.getCustomPictogramsByCategory(category.key);
        if (customPictograms.isNotEmpty) {
          // Add custom pictograms to results
          finalResults.addAll(customPictograms);
          if (kDebugMode) {
            debugPrint('Category search [${category.key}]: Added ${customPictograms.length} custom pictograms');
          }
        }
      } catch (e) {
        // Fail silently if custom pictograms can't be loaded
        if (kDebugMode) {
          debugPrint('Category search [${category.key}]: Error loading custom pictograms: $e');
        }
      }
      
      // Return merged results (ARASAAC + custom pictograms)
      return finalResults;
    } on SocketException {
      // Offline - return empty list silently
      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Offline - cannot search pictograms');
      }
      return [];
    } catch (e) {
      // Any other error - try broader search as fallback
      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Error in multi-keyword search: $e');
      }
      
      // Try broader search, but catch any exceptions there too
      try {
        return await _tryBroaderSearch(category, limit);
      } catch (_) {
        // Broader search also failed - return empty list
        return [];
      }
    }
  }

  /// Single keyword search (used when keyword parameter is provided).
  /// 
  /// This maintains backward compatibility for direct keyword searches.
  /// Uses the UI language for keyword searches (not English like category searches).
  /// 
  /// [category] - The category to assign results to
  /// [keyword] - The search keyword
  /// [limit] - Maximum number of results
  /// Returns a list of Pictogram objects
  Future<List<Pictogram>> _singleKeywordSearch(
    PictogramCategory category,
    String keyword,
    int limit,
  ) async {
    try {
      final encodedQuery = Uri.encodeComponent(keyword.toLowerCase().trim());
      // Use Dutch language to get Dutch keywords in response
      final url = _buildSearchUrl(encodedQuery, language: 'nl');
      
      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final results = _parseSearchResponse(response.body, category, limit);
        
        // Enhance all results with Dutch keywords
        // Return results without enhancement to prevent hanging
        // The search API already returns keywords in the requested language
        return results;
      }
    } on SocketException {
      // Offline - return empty list silently
      if (kDebugMode) {
        debugPrint('Keyword search: Offline - cannot search for "$keyword"');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Keyword search: Error searching for "$keyword": $e');
      }
    }
    
    return [];
  }

  /// Get a single pictogram by ID from ARASAAC API.
  /// 
  /// Fetches the pictogram details including keywords directly by ID.
  /// This is more reliable than searching by ID as a keyword.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// 
  /// Returns a Pictogram object with keyword, or null if not found/offline
  Future<Pictogram?> getPictogramById(int pictogramId) async {
    try {
      // ARASAAC API endpoint format: /api/pictograms/{id}
      // Some endpoints return PNG images, so we need to check content-type
      // Always try endpoints that are more likely to return JSON metadata first
      final urls = [
        // Try with explicit JSON request parameters
        Uri.parse('$_baseUrl/pictograms/$pictogramId?download=false&url=true&locale=nl'),
        Uri.parse('$_baseUrl/pictograms/$pictogramId?download=false&url=true&locale=en'),
        Uri.parse('$_baseUrl/pictograms/$pictogramId?download=false&url=true'),
        // Try locale-specific endpoints
        Uri.parse('$_baseUrl/pictograms/$pictogramId?locale=nl'),
        Uri.parse('$_baseUrl/pictograms/$pictogramId?locale=en'),
        // Last resort: base endpoint (may return image, but we check content-type)
        Uri.parse('$_baseUrl/pictograms/$pictogramId'),
      ];
      
      for (final url in urls) {
        try {
          final response = await http.get(url).timeout(
            _requestTimeout,
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );
          
          if (response.statusCode == 200) {
            // Check if response is JSON (not an image)
            final contentType = response.headers['content-type'] ?? '';
            final bodyBytes = response.bodyBytes;
            
            // Check if response is PNG image (starts with PNG signature)
            if (bodyBytes.length >= 4) {
              final pngSignature = [0x89, 0x50, 0x4E, 0x47]; // PNG file signature
              final isPng = bodyBytes[0] == pngSignature[0] &&
                           bodyBytes[1] == pngSignature[1] &&
                           bodyBytes[2] == pngSignature[2] &&
                           bodyBytes[3] == pngSignature[3];
              
              if (isPng) {
                // This is a PNG image, skip it and try next URL
                continue;
              }
            }
            
            // Check content-type header
            if (contentType.contains('application/json') || 
                contentType.contains('text/json') ||
                contentType.isEmpty) {
              try {
                final dynamic decoded = json.decode(response.body);
                if (decoded is Map) {
                  // Parse the pictogram from the response
                  final keyword = _extractKeyword(decoded);
                  if (keyword.isNotEmpty && keyword != 'Onbekend') {
                    return Pictogram(
                      id: pictogramId,
                      keyword: keyword,
                      category: 'fetched', // Generic category
                      imageUrl: getStaticImageUrl(pictogramId),
                      description: _extractDescription(decoded),
                    );
                  }
                }
              } catch (jsonError) {
                // Response is not valid JSON (might be image or other format)
                // Silently skip and try next URL
                continue;
              }
            } else {
              // Response is not JSON (image or other format), skip it
              continue;
            }
          }
        } catch (e) {
          // Try next URL
          if (kDebugMode) {
            // Only log non-FormatException errors (FormatException means it's an image, which is expected)
            if (e is! FormatException) {
              debugPrint('Error fetching from $url: $e');
            }
          }
          continue;
        }
      }
    } on SocketException {
      // Offline - return null silently
      if (kDebugMode) {
        debugPrint('Offline: Cannot fetch pictogram $pictogramId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching pictogram $pictogramId: $e');
      }
    }
    
    return null;
  }

  /// Search pictograms by any keyword (for search bar functionality).
  /// 
  /// This is a simpler search that searches across all categories using
  /// the provided keyword. Useful for general search functionality.
  /// 
  /// When offline, returns an empty list (no exceptions thrown).
  /// Use getCachedPictograms() to retrieve cached pictograms by ID.
  /// 
  /// [keyword] - The search keyword
  /// [limit] - Maximum number of results to return (default: 100)
  /// 
  /// Returns a list of Pictogram objects matching the keyword
  /// Returns empty list if offline or on error (never throws exceptions)
  Future<List<Pictogram>> searchByKeyword(String keyword, {int limit = _defaultLimit}) async {
    try {
      final encodedQuery = Uri.encodeComponent(keyword.toLowerCase().trim());
      // Use Dutch language to get Dutch keywords in response
      final url = _buildSearchUrl(encodedQuery, language: 'nl');
      
      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        // Use a generic category for search results
        final category = PictogramCategory.diversen;
        final results = _parseSearchResponse(response.body, category, limit);
        
        // Merge with custom pictograms that match the keyword
        try {
          final allCustomPictograms = await _customPictogramService.getAllCustomPictograms();
          final matchingCustom = allCustomPictograms.where((p) {
            return p.keyword.toLowerCase().contains(keyword.toLowerCase());
          }).toList();
          
          if (matchingCustom.isNotEmpty) {
            results.addAll(matchingCustom);
            if (kDebugMode) {
              debugPrint('Keyword search: Added ${matchingCustom.length} matching custom pictograms');
            }
          }
        } catch (e) {
          // Fail silently if custom pictograms can't be loaded
          if (kDebugMode) {
            debugPrint('Keyword search: Error loading custom pictograms: $e');
          }
        }
        
        // Enhance all results with Dutch keywords
        // Return results without enhancement to prevent hanging
        // The search API already returns keywords in the requested language
        return results;
      }
    } on SocketException {
      // Offline - return empty list silently
      if (kDebugMode) {
        debugPrint('Offline: Cannot search by keyword');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in searchByKeyword: $e');
      }
    }
    
    return [];
  }

  /// Build the ARASAAC search API URL with specified language.
  /// 
  /// Centralizes URL construction for all search operations.
  /// Allows overriding language for category searches (English) vs keyword searches (UI language).
  /// 
  /// [encodedQuery] - The URL-encoded search query
  /// [language] - The language code to use (defaults to current _language)
  /// Returns the complete search API URL as a Uri
  Uri _buildSearchUrl(String encodedQuery, {String? language}) {
    final lang = language ?? _language;
    return Uri.parse('$_baseUrl/pictograms/$lang/search/$encodedQuery');
  }


  /// Parse the ARASAAC API search response into Pictogram objects.
  /// 
  /// Handles different response formats:
  /// - Direct array: [ {...}, {...} ]
  /// - Object with results: { "results": [...] }
  /// 
  /// [responseBody] - The JSON response body from ARASAAC API
  /// [category] - The category to assign to parsed pictograms
  /// [limit] - Maximum number of pictograms to return
  /// 
  /// Returns a list of parsed Pictogram objects
  List<Pictogram> _parseSearchResponse(
    String responseBody,
    PictogramCategory category,
    int limit,
  ) {
    if (responseBody.isEmpty) {
      return [];
    }
    
    try {
      final dynamic decoded = json.decode(responseBody);
      List<dynamic> data;
      
      // Handle different response formats
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('results')) {
        data = decoded['results'] as List<dynamic>? ?? [];
      } else {
        data = [];
      }
      
      if (data.isEmpty) {
        return [];
      }
      
      // Limit results and parse each item
      final limitedData = data.take(limit).toList();
      final pictograms = <Pictogram>[];
      
      for (var item in limitedData) {
        final pictogram = _parsePictogramItem(item, category);
        if (pictogram != null) {
          pictograms.add(pictogram);
        }
      }
      
      return pictograms;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing search response: $e');
      }
      return [];
    }
  }

  /// Parse a single pictogram item from ARASAAC API response.
  /// 
  /// Extracts:
  /// - ID (handles both int and string formats)
  /// - Keyword (preferred: UI language, fallback: any available)
  /// - Optional description
  /// 
  /// [item] - The JSON item from ARASAAC API
  /// [category] - The category to assign to the pictogram
  /// 
  /// Returns a Pictogram object or null if parsing fails.
  /// 
  /// Always extracts Dutch keywords for display, regardless of user language setting.
  /// This ensures consistent Dutch display in the pictogram picker.
  Pictogram? _parsePictogramItem(dynamic item, PictogramCategory category) {
    try {
      if (item is! Map) {
        return null;
      }
      
      // Extract ID - ARASAAC uses '_id' or 'id' field
      final id = _extractPictogramId(item);
      if (id <= 0) {
        return null; // Invalid ID
      }
      
      // Extract keyword - always prefer Dutch for display (regardless of user language)
      // getLocalizedKeyword() already prioritizes Dutch, so this will work correctly
      final keyword = _extractKeyword(item);
      
      // Extract optional description
      final description = _extractDescription(item);
      
      return Pictogram(
        id: id,
        keyword: keyword,
        category: category.key,
        imageUrl: getStaticImageUrl(id),
        description: description,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing pictogram item: $e');
      }
      return null;
    }
  }

  /// Extract pictogram ID from API response item.
  /// 
  /// Handles both integer and string ID formats from ARASAAC API.
  /// Returns 0 if ID is invalid or missing.
  int _extractPictogramId(Map<dynamic, dynamic> item) {
    dynamic idValue = item['_id'] ?? item['id'];
    
    if (idValue is int) {
      return idValue;
    } else if (idValue is String) {
      return int.tryParse(idValue) ?? 0;
    }
    
    return 0;
  }

  /// Extract localized keyword from ARASAAC API response.
  /// 
  /// This method extracts keywords with the following priority:
  /// 1. Dutch ("nl") - preferred for display
  /// 2. English ("en") - fallback if Dutch not available
  /// 3. Any other language - if neither Dutch nor English exists
  /// 4. "Onbekend" - if no keywords found
  /// 
  /// This ensures consistent Dutch-first display regardless of search language.
  /// ARASAAC searches use English for better results, but displayed labels
  /// always prefer Dutch for caregiver-friendly UI.
  /// 
  /// [keywords] - The keywords array from ARASAAC API response
  /// Returns the localized keyword string
  String getLocalizedKeyword(List<dynamic> keywords) {
    if (keywords.isEmpty) {
      return 'Onbekend';
    }
    
    String? dutchKeyword;
    String? englishKeyword;
    String? anyKeyword; // Fallback to any available keyword
    
    // Search through all keywords to find Dutch and English versions
    for (var k in keywords) {
      if (k is Map) {
        // Try multiple possible field names for keyword text
        final keywordText = (k['keyword'] as String?) ?? 
                           (k['text'] as String?) ?? 
                           (k['name'] as String?);
        final locale = (k['locale'] as String?) ?? 
                      (k['language'] as String?) ?? 
                      (k['lang'] as String?);
        
        if (keywordText != null && keywordText.trim().isNotEmpty) {
          final trimmedKeyword = keywordText.trim();
          // Prefer Dutch ("nl")
          if ((locale == 'nl' || locale == 'dutch' || locale == 'nederlands') && dutchKeyword == null) {
            dutchKeyword = trimmedKeyword;
          }
          // Fallback to English ("en")
          else if ((locale == 'en' || locale == 'english' || locale == 'engels') && englishKeyword == null) {
            englishKeyword = trimmedKeyword;
          }
          // Store any keyword as last resort
          anyKeyword ??= trimmedKeyword;
          
          // Early exit if we found Dutch (preferred)
          if (dutchKeyword != null) {
            break;
          }
        }
      } else if (k is String) {
        // If keyword is a simple string, use it as fallback
        if (anyKeyword == null && k.trim().isNotEmpty) {
          anyKeyword = k.trim();
        }
      }
    }
    
    // Return in priority order: Dutch > English > Any > "Onbekend"
    return dutchKeyword ?? englishKeyword ?? anyKeyword ?? 'Onbekend';
  }

  /// Extract keyword from API response item, always prioritizing Dutch.
  /// 
  /// This is a convenience method that extracts the keywords array from
  /// the API response item and calls getLocalizedKeyword().
  /// 
  /// ARASAAC returns keywords as an array with locale information.
  /// This method ALWAYS prefers Dutch ("nl") for display, regardless of user language setting.
  /// This ensures consistent Dutch display in the pictogram picker.
  /// 
  /// Priority order: Dutch > English > Any available keyword > "Onbekend"
  /// 
  /// Also checks alternative fields like 'name', 'text', 'keyword' as fallbacks.
  /// 
  /// [item] - The JSON item from ARASAAC API
  /// Returns the Dutch keyword if available, otherwise English, then any, then "Onbekend"
  String _extractKeyword(Map<dynamic, dynamic> item) {
    // First, try to get keywords array (preferred method)
    final keywords = item['keywords'] as List<dynamic>?;
    
    if (keywords != null && keywords.isNotEmpty) {
      final localizedKeyword = getLocalizedKeyword(keywords);
      // Only return "Onbekend" if getLocalizedKeyword actually found nothing
      if (localizedKeyword != 'Onbekend') {
        return localizedKeyword;
      }
    }
    
    // Fallback 1: Check for direct 'keyword' field (string)
    final directKeyword = item['keyword'] as String?;
    if (directKeyword != null && directKeyword.trim().isNotEmpty) {
      return directKeyword.trim();
    }
    
    // Fallback 2: Check for 'name' field
    final name = item['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    
    // Fallback 3: Check for 'text' field
    final text = item['text'] as String?;
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }
    
    // Fallback 4: Check for 'description' field
    final description = item['description'] as String?;
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }
    
    // Last resort: return "Onbekend"
    return 'Onbekend';
  }

  /// Extract description from API response item.
  /// 
  /// ARASAAC sometimes provides a 'meaning' field in the keywords array.
  /// Returns null if description is not available.
  String? _extractDescription(Map<dynamic, dynamic> item) {
    final keywords = item['keywords'] as List<dynamic>?;
    
    if (keywords != null && keywords.isNotEmpty) {
      final firstKeyword = keywords.first;
      if (firstKeyword is Map<String, dynamic>) {
        return firstKeyword['meaning'] as String?;
      }
    }
    
    return null;
  }

  /// Try fallback searches using generic categories when initial search has very few results.
  /// 
  /// This method attempts to find pictograms from generic categories:
  /// - Daily activities (eten, beweging, tijd)
  /// - Personal care (lichaam, gezondheid)
  /// 
  /// Only used when original search returns 0-2 results to maintain category relevance.
  /// This prevents mixing unrelated categories (e.g., work with eating).
  /// 
  /// Increased fallback cap from 10 to 40 to provide more results when needed.
  /// 
  /// [originalCategory] - The original category that had few results
  /// [limit] - Maximum number of results to return
  /// [currentCount] - Current number of results found
  /// 
  /// Returns a list of Pictogram objects from fallback categories
  Future<List<Pictogram>> _tryFallbackSearches(
    PictogramCategory originalCategory,
    int limit,
    int currentCount,
  ) async {
    // Only use fallback if we have very few results (0-2) to maintain category relevance
    if (currentCount > 2) {
      return [];
    }
    
    final fallbackResults = <Pictogram>[];
    final seenIds = <int>{};
    
    // Define generic fallback categories for daily activities and personal care
    final dailyActivityCategories = [
      PictogramCategory.eten,      // Feeding - common daily activity
      PictogramCategory.beweging,  // Movement - daily activities
      PictogramCategory.tijd,      // Time - daily routines
    ];
    
    final personalCareCategories = [
      PictogramCategory.lichaam,    // Body - personal care
      PictogramCategory.gezondheid, // Health - personal care
    ];
    
    // Try daily activities categories first
    for (var fallbackCategory in dailyActivityCategories) {
      // Skip if it's the same as original category
      if (fallbackCategory == originalCategory) continue;
      
      try {
        // Use multi-keyword search for fallback categories too
        final searchTerms = _getCategorySearchTerms(fallbackCategory);
        
        for (final term in searchTerms.take(3)) { // Limit to 3 terms per fallback category
          final encodedQuery = Uri.encodeComponent(term);
          final url = _buildSearchUrl(encodedQuery, language: _categorySearchLanguage);
          
          final response = await http.get(url).timeout(
            _requestTimeout,
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );
          
          if (response.statusCode == 200) {
            final pictograms = _parseSearchResponse(response.body, fallbackCategory, 20);
            
            // Add unique pictograms to fallback results
            for (var pictogram in pictograms) {
              if (!seenIds.contains(pictogram.id)) {
                seenIds.add(pictogram.id);
                fallbackResults.add(pictogram);
                if (fallbackResults.length >= 40) break; // Increased cap from 10 to 40
              }
            }
            
            if (kDebugMode && pictograms.isNotEmpty) {
              debugPrint('Fallback search: Found ${pictograms.length} pictograms in ${fallbackCategory.key}');
            }
          }
          
          if (fallbackResults.length >= 40) break; // Increased cap from 10 to 40
        }
      } on SocketException {
        // Offline - skip this fallback
        continue;
      } catch (e) {
        // Error - skip this fallback
        if (kDebugMode) {
          debugPrint('Error in fallback search for ${fallbackCategory.key}: $e');
        }
        continue;
      }
      
      // Stop if we have enough results (increased cap)
      if (fallbackResults.length >= 40) break;
    }
    
    // If still need more, try personal care categories
    if (fallbackResults.length < 40) {
      for (var fallbackCategory in personalCareCategories) {
        // Skip if it's the same as original category
        if (fallbackCategory == originalCategory) continue;
        
        try {
          // Use multi-keyword search for fallback categories too
          final searchTerms = _getCategorySearchTerms(fallbackCategory);
          
          for (final term in searchTerms.take(3)) { // Limit to 3 terms per fallback category
            final encodedQuery = Uri.encodeComponent(term);
            final url = _buildSearchUrl(encodedQuery, language: _categorySearchLanguage);
            
            final response = await http.get(url).timeout(
              _requestTimeout,
              onTimeout: () {
                throw Exception('Request timeout');
              },
            );
            
            if (response.statusCode == 200) {
              final pictograms = _parseSearchResponse(response.body, fallbackCategory, 20);
              
              // Add unique pictograms to fallback results
              for (var pictogram in pictograms) {
                if (!seenIds.contains(pictogram.id)) {
                  seenIds.add(pictogram.id);
                  fallbackResults.add(pictogram);
                  if (fallbackResults.length >= 40) break; // Increased cap from 10 to 40
                }
              }
              
              if (kDebugMode && pictograms.isNotEmpty) {
                debugPrint('Fallback search: Found ${pictograms.length} pictograms in ${fallbackCategory.key}');
              }
            }
            
            if (fallbackResults.length >= 40) break; // Increased cap from 10 to 40
          }
        } on SocketException {
          // Offline - skip this fallback
          continue;
        } catch (e) {
          // Error - skip this fallback
          if (kDebugMode) {
            debugPrint('Error in fallback search for ${fallbackCategory.key}: $e');
          }
          continue;
        }
        
        // Stop if we have enough results (increased cap)
        if (fallbackResults.length >= 40) break;
      }
    }
    
    return fallbackResults;
  }

  /// Try a broader search if the initial search fails.
  /// 
  /// This fallback method uses only the category's English search term
  /// instead of the full keyword list. Useful when specific searches
  /// return no results.
  /// 
  /// Returns empty list if offline or on error (never throws exceptions).
  /// 
  /// [category] - The category to search
  /// [limit] - Maximum number of results to return
  /// 
  /// Returns a list of Pictogram objects or empty list if search fails
  Future<List<Pictogram>> _tryBroaderSearch(
    PictogramCategory category,
    int limit,
  ) async {
    try {
      // Use only the English search term for broader results
      final broadTerm = category.searchTerm;
      final encodedQuery = Uri.encodeComponent(broadTerm);
      // Use English for broader search
      final url = _buildSearchUrl(encodedQuery, language: _categorySearchLanguage);
      
      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final results = _parseSearchResponse(response.body, category, limit);
        
        // Enhance all results with Dutch keywords
        // Return results without enhancement to prevent hanging
        // The search API already returns keywords in the requested language
        return results;
      }
    } on SocketException {
      // Offline - return empty list silently
      if (kDebugMode) {
        debugPrint('Offline: Cannot perform broader search');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in broader search: $e');
      }
    }
    
    return [];
  }

  // ============================================================================
  // Image URL Generation
  // ============================================================================

  /// Get the ARASAAC API endpoint URL for a pictogram.
  /// 
  /// This uses the ARASAAC API endpoint which may return a redirect or
  /// direct image URL. Less reliable than static URLs but useful as fallback.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns the API endpoint URL
  String getImageUrl(int pictogramId) {
    return '$_baseUrl/pictograms/$pictogramId?download=false&url=true';
  }

  /// Get static image URL for a pictogram (highest quality - 5000px).
  /// 
  /// ARASAAC static URL format: https://static.arasaac.org/pictograms/{id}/{id}_5000.png
  /// Size 5000 is the highest quality available and recommended for best visual results.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns the static image URL with 5000px size
  String getStaticImageUrl(int pictogramId) {
    return getStaticImageUrlWithSize(pictogramId, size: 5000);
  }

  /// Get static image URL with a specific size.
  /// 
  /// ARASAAC provides multiple image sizes:
  /// - 5000: Highest quality (recommended for fullscreen)
  /// - 2500: High quality
  /// - 1500: Medium quality
  /// - 1000: Lower quality
  /// - 500: Low quality (for thumbnails)
  /// - 300: Very low quality (for grid displays)
  /// 
  /// Format: https://static.arasaac.org/pictograms/{id}/{id}_{size}.png
  /// 
  /// For custom pictograms (negative IDs), returns the Firebase Storage URL directly.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID (or custom pictogram ID if negative)
  /// [size] - Image size in pixels (default: 5000, ignored for custom pictograms)
  /// Returns the static image URL with specified size
  String getStaticImageUrlWithSize(int pictogramId, {int size = 5000}) {
    // Check if this is a custom pictogram (negative ID)
    if (CustomPictogramService.isCustomPictogram(pictogramId)) {
      // For custom pictograms, the imageUrl should be set in the Pictogram model
      // Return empty string as fallback (caller should use pictogram.imageUrl)
      return '';
    }
    
    // Standard ARASAAC URL
    return '$_imageBaseUrl/$pictogramId/${pictogramId}_$size.png';
  }

  /// Get thumbnail image URL for a pictogram (500px).
  /// 
  /// Optimized for small previews and grid displays. Use this for:
  /// - Thumbnail images in lists
  /// - Small preview cards
  /// - Grid layouts with many items
  /// 
  /// Provides good balance between quality and performance.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns the thumbnail image URL (500px)
  String getThumbnailUrl(int pictogramId) {
    // For custom pictograms, return empty (caller should use pictogram.imageUrl)
    if (CustomPictogramService.isCustomPictogram(pictogramId)) {
      return '';
    }
    return getStaticImageUrlWithSize(pictogramId, size: 500);
  }

  /// Get preview image URL for a pictogram (1000px).
  /// 
  /// Optimized for medium-sized displays. Use this for:
  /// - Preview images in detail views
  /// - Medium-sized cards
  /// - Single-item displays that need better quality than thumbnails
  /// 
  /// Provides better quality than thumbnails while maintaining good performance.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns the preview image URL (1000px)
  String getPreviewUrl(int pictogramId) {
    return getStaticImageUrlWithSize(pictogramId, size: 1000);
  }

  /// Get the best quality image URL for a pictogram.
  /// 
  /// Currently returns the 5000px version which is ARASAAC's highest quality.
  /// This method provides a semantic way to request the best available quality.
  /// 
  /// Recommended for:
  /// - Fullscreen client mode displays
  /// - High-quality presentations
  /// - When maximum detail is required
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns the highest quality static image URL (5000px)
  String getBestQualityImageUrl(int pictogramId) {
    return getStaticImageUrl(pictogramId);
  }

  /// Get alternative image URL formats for a pictogram.
  /// 
  /// Useful for fallback scenarios when the primary URL format fails.
  /// Returns multiple URL formats that can be tried in sequence.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// Returns a list of alternative URL formats to try
  List<String> getImageUrlAlternatives(int pictogramId) {
    return [
      getStaticImageUrlWithSize(pictogramId, size: 5000), // Standard format
      '$_imageBaseUrl/$pictogramId/$pictogramId.png', // Without size suffix
      getImageUrl(pictogramId), // API endpoint
    ];
  }

  // ============================================================================
  // Attribution
  // ============================================================================

  /// Get the ARASAAC attribution text.
  /// 
  /// Returns the required attribution text for ARASAAC pictograms.
  /// This should be displayed wherever ARASAAC pictograms are used.
  /// 
  /// Format: "Pictograms by ARASAAC (https://arasaac.org), used under CC BY-NC-SA license"
  /// 
  /// Returns the attribution text string
  String getAttributionText() {
    return 'Pictograms by ARASAAC (${getAttributionUrl()}), used under CC BY-NC-SA license';
  }

  /// Get the ARASAAC website URL.
  /// 
  /// Returns the official ARASAAC website URL for attribution purposes.
  /// 
  /// Returns the ARASAAC website URL
  String getAttributionUrl() {
    return 'https://arasaac.org';
  }
}
