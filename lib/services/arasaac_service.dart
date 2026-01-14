import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/pictogram_model.dart';

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
  
  /// Target number of pictograms per category (40-80 range)
  static const int _targetCategoryResults = 60;
  
  /// Maximum number of API calls per category search (safety limit)
  static const int _maxApiCallsPerCategory = 10;
  
  /// Cache directory name within app documents
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

  /// Cache an image locally by writing it to disk.
  /// 
  /// [pictogramId] - The ARASAAC pictogram ID
  /// [imageData] - The image bytes to cache
  Future<void> _cacheImage(int pictogramId, List<int> imageData) async {
    final cachePath = await _getCachePath(pictogramId);
    final file = File(cachePath);
    await file.writeAsBytes(imageData);
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
  Future<File?> downloadAndCachePictogram(int pictogramId) async {
    try {
      // Check if already cached
      final cached = await getCachedImage(pictogramId);
      if (cached != null) {
        return cached;
      }

      // Download image (using highest quality 5000px)
      final imageUrl = getStaticImageUrlWithSize(pictogramId, size: 5000);
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        // Cache the image
        await _cacheImage(pictogramId, response.bodyBytes);
        return await getCachedImage(pictogramId);
      }
    } on SocketException {
      // Offline - fail silently
      if (kDebugMode) {
        debugPrint('Offline: Cannot download pictogram $pictogramId');
      }
    } catch (e) {
      // Any other error - fail silently
      if (kDebugMode) {
        debugPrint('Error downloading pictogram $pictogramId: $e');
      }
    }
    
    return null;
  }

  /// Get cached pictograms by their IDs.
  /// 
  /// This method is useful for offline scenarios where you have a list of
  /// pictogram IDs and want to retrieve only those that are cached locally.
  /// 
  /// Returns Pictogram objects for IDs that are cached. IDs that are not
  /// cached are silently skipped (not included in the result).
  /// 
  /// [ids] - List of ARASAAC pictogram IDs to retrieve
  /// 
  /// Returns a list of Pictogram objects for cached IDs only
  Future<List<Pictogram>> getCachedPictograms(List<int> ids) async {
    final cachedPictograms = <Pictogram>[];
    
    for (final id in ids) {
      try {
        // Check if this pictogram is cached
        final isCachedPictogram = await isCached(id);
        
        if (isCachedPictogram) {
          // Create a Pictogram object for the cached image
          // Note: We don't have keyword/category info from cache, so we use defaults
          cachedPictograms.add(Pictogram(
            id: id,
            keyword: 'Pictogram $id', // Default keyword since we don't store metadata
            category: 'cached', // Generic category for cached items
            imageUrl: getStaticImageUrl(id),
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

  /// Get multiple search terms for a category to maximize results.
  /// 
  /// Each category has a primary search term and additional related terms
  /// that help find more relevant pictograms. This method returns a list
  /// of search terms to query separately and merge results.
  /// 
  /// [category] - The pictogram category
  /// Returns a list of search terms (English) for this category
  List<String> _getCategorySearchTerms(PictogramCategory category) {
    switch (category) {
      case PictogramCategory.eten:
        return ['eat', 'drink', 'food', 'meal', 'breakfast', 'lunch', 'dinner', 'snack', 'cook', 'kitchen'];
      case PictogramCategory.vrijetijd:
        return ['leisure', 'hobby', 'sport', 'game', 'play', 'fun', 'entertainment', 'recreation', 'activity'];
      case PictogramCategory.plaats:
        return ['place', 'location', 'building', 'room', 'house', 'home', 'office', 'shop', 'store'];
      case PictogramCategory.levendWezen:
        return ['animal', 'person', 'people', 'human', 'pet', 'dog', 'cat', 'bird'];
      case PictogramCategory.onderwijs:
        return ['education', 'school', 'learn', 'study', 'teacher', 'student', 'class', 'book', 'read'];
      case PictogramCategory.tijd:
        return ['time', 'hour', 'day', 'week', 'month', 'year', 'morning', 'afternoon', 'evening', 'night'];
      case PictogramCategory.diversen:
        return ['miscellaneous', 'other', 'various', 'general', 'common'];
      case PictogramCategory.beweging:
        return ['movement', 'walk', 'run', 'move', 'go', 'travel', 'exercise', 'sport'];
      case PictogramCategory.religie:
        return ['religion', 'faith', 'church', 'pray', 'worship', 'spiritual'];
      case PictogramCategory.werk:
        return ['work', 'job', 'profession', 'office', 'career', 'task', 'business', 'labor'];
      case PictogramCategory.communicatie:
        return ['communication', 'talk', 'speak', 'phone', 'call', 'message', 'chat', 'conversation'];
      case PictogramCategory.document:
        return ['document', 'paper', 'letter', 'file', 'form', 'note', 'write'];
      case PictogramCategory.kennis:
        return ['knowledge', 'information', 'data', 'fact', 'learn', 'understand', 'know'];
      case PictogramCategory.object:
        return ['object', 'thing', 'item', 'tool', 'device', 'equipment', 'material'];
      case PictogramCategory.gevoelens:
        return ['emotion', 'feeling', 'happy', 'sad', 'angry', 'love', 'fear', 'joy', 'worry'];
      case PictogramCategory.gezondheid:
        return ['health', 'medicine', 'doctor', 'hospital', 'medical', 'treatment', 'care', 'wellness'];
      case PictogramCategory.lichaam:
        return ['body', 'part', 'head', 'hand', 'foot', 'eye', 'ear', 'mouth', 'face', 'arm', 'leg'];
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

      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Using ${searchTerms.length} search terms');
      }

      // Search each term separately and merge results
      for (final term in searchTerms) {
        // Safety limit: don't exceed max API calls
        if (apiCallCount >= _maxApiCallsPerCategory) {
          if (kDebugMode) {
            debugPrint('Category search [${category.key}]: Reached API call limit ($_maxApiCallsPerCategory)');
          }
          break;
        }

        try {
          final encodedQuery = Uri.encodeComponent(term);
          // Use English for category searches (better ARASAAC coverage)
          final url = _buildSearchUrl(encodedQuery, language: _categorySearchLanguage);
          
          final response = await http.get(url).timeout(
            _requestTimeout,
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

          apiCallCount++;

          if (response.statusCode == 200) {
            // Parse results with a per-term limit to avoid too many duplicates
            final termResults = _parseSearchResponse(
              response.body,
              category,
              _targetCategoryResults, // Get more per term to ensure good merge
            );

            int addedFromTerm = 0;
            for (var pictogram in termResults) {
              // Only add if not already seen (deduplicate)
              if (!seenIds.contains(pictogram.id)) {
                seenIds.add(pictogram.id);
                mergedResults.add(pictogram);
                addedFromTerm++;

                // Stop if we've reached the target
                if (mergedResults.length >= _targetCategoryResults) {
                  break;
                }
              }
            }

            if (kDebugMode && addedFromTerm > 0) {
              debugPrint('Category search [${category.key}]: Term "$term" returned $addedFromTerm new pictograms (total: ${mergedResults.length})');
            }

            // Early exit if we have enough results
            if (mergedResults.length >= _targetCategoryResults) {
              break;
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

      // Limit final results to requested limit
      final finalResults = mergedResults.take(limit).toList();

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
      
      // Return merged results (maintain category relevance)
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
      // Use UI language for keyword searches (user's preference)
      final url = _buildSearchUrl(encodedQuery, language: _language);
      
      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        return _parseSearchResponse(response.body, category, limit);
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
      // Use UI language for keyword searches
      final url = _buildSearchUrl(encodedQuery, language: _language);
      
      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        // Use a generic category for search results
        final category = PictogramCategory.diversen;
        return _parseSearchResponse(response.body, category, limit);
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
  /// Returns a Pictogram object or null if parsing fails
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
      
      // Extract keyword (preferred: UI language, fallback: any available)
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
  /// 3. "Onbekend" - if neither Dutch nor English exists
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
    
    // Search through all keywords to find Dutch and English versions
    for (var k in keywords) {
      if (k is Map) {
        final keywordText = k['keyword'] as String?;
        final locale = k['locale'] as String?;
        
        if (keywordText != null && locale != null) {
          // Prefer Dutch ("nl")
          if (locale == 'nl' && dutchKeyword == null) {
            dutchKeyword = keywordText;
          }
          // Fallback to English ("en")
          if (locale == 'en' && englishKeyword == null) {
            englishKeyword = keywordText;
          }
          
          // Early exit if we found both
          if (dutchKeyword != null && englishKeyword != null) {
            break;
          }
        }
      }
    }
    
    // Return in priority order: Dutch > English > "Onbekend"
    return dutchKeyword ?? englishKeyword ?? 'Onbekend';
  }

  /// Extract keyword from API response item using localized preference.
  /// 
  /// This is a convenience method that extracts the keywords array from
  /// the API response item and calls getLocalizedKeyword().
  /// 
  /// ARASAAC returns keywords as an array with locale information.
  /// This method always prefers Dutch ("nl") for display, then English ("en"),
  /// then "Onbekend" if neither exists.
  /// 
  /// [item] - The JSON item from ARASAAC API
  /// Returns the localized keyword string
  String _extractKeyword(Map<dynamic, dynamic> item) {
    final keywords = item['keywords'] as List<dynamic>?;
    
    if (keywords == null || keywords.isEmpty) {
      return 'Onbekend';
    }
    
    return getLocalizedKeyword(keywords);
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
        return _parseSearchResponse(response.body, category, limit);
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
  /// [pictogramId] - The ARASAAC pictogram ID
  /// [size] - Image size in pixels (default: 5000)
  /// Returns the static image URL with specified size
  String getStaticImageUrlWithSize(int pictogramId, {int size = 5000}) {
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
