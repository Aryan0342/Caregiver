import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/pictogram_model.dart';
import 'custom_pictogram_service.dart';

class ArasaacService {
  final CustomPictogramService _customPictogramService = CustomPictogramService();

  // NOTE: All explicit ARASAAC disk caching has been disabled. The app now
  // always works online and does not store pictogram images on disk.
  Future<void> _metadataWriteLock = Future<void>.value();

  static const String _baseUrl = 'https://api.arasaac.org/api';

  static const String _imageBaseUrl = 'https://static.arasaac.org/pictograms';

  static const Duration _requestTimeout = Duration(seconds: 10);

  static const int _defaultLimit = 100;

  static const int _maxApiCallsPerCategory = 100;

  // Deprecated cache constants (kept only for backward compatibility)
  static const String _cacheMetadataFile = 'cache_metadata.json';
  static const String _cacheDirectoryName = 'pictogram_cache';

  static const String _defaultLanguage = 'nl';

  static const String _categorySearchLanguage = 'en';

  String _language = _defaultLanguage;

  String get language => _language;

  void setLanguage(String languageCode) {
    _language = languageCode.toLowerCase().trim();
  }

  // =========================
  // DISABLED DISK CACHE (ONLINE ONLY)
  // =========================

  /// Offline disk caching is disabled. These members are kept as no-ops or
  /// trivial implementations so existing call sites do not break.

  Directory? _cacheDir;

  Future<Directory?> getCacheDirectory() async {
    // No disk cache directory is used anymore.
    return null;
  }

  Future<void> _initCache() async {
    // No-op: cache directory initialization disabled.
  }

  Future<String> _getCachePath(int pictogramId) async {
    // No-op path; callers should not rely on this while cache is disabled.
    return '';
  }

  Future<bool> isCached(int pictogramId) async {
    // Always report not cached when offline cache is disabled.
    return false;
  }

  Future<File?> getCachedImage(int pictogramId) async {
    // No cached image available when offline cache is disabled.
    return null;
  }

  Future<String> _getMetadataPath() async {
    // No metadata file when cache is disabled.
    return '';
  }

  Future<Map<int, String>> _loadCacheMetadata() async {
    // No metadata is stored while offline cache is disabled.
    return {};
  }

  Future<void> _saveCacheMetadata(Map<int, String> metadata) async {
    // No-op: metadata is not written to disk anymore.
  }

  Future<void> _cacheImage(
    int pictogramId,
    List<int> imageData, {
    required String category,
    required String keyword,
  }) async {
    // No-op: images are no longer cached to disk.
  }

  Future<void> clearCacheForCategory(String category) async {
    // No-op: category-based cache is no longer used.
  }

  Future<File?> downloadAndCachePictogramAtSize(int pictogramId, {int size = 500, required String category, required String keyword}) async {
    // Disk-based caching has been disabled. This method is kept only for
    // backward compatibility and now always returns null so that callers
    // fall back to using online image URLs directly.
    return null;
  }

  Future<File?> downloadAndCachePictogram(int pictogramId, {required String category, required String keyword}) async {
    return await downloadAndCachePictogramAtSize(pictogramId, size: 500, category: category, keyword: keyword);
  }

  Future<List<Pictogram>> getCachedPictograms({List<int>? ids, String? category}) async {
    // Offline pictogram cache has been removed. Always return an empty list.
    return [];
  }

  Future<void> clearAllPictogramCacheFully() async {
    // No-op: explicit pictogram cache is no longer used (online-only mode).
  }

  Future<int> getCacheSize() async {
    // Always zero because no disk cache is maintained anymore.
    return 0;
  }


  List<String> _getCategorySearchTerms(PictogramCategory category) {
    switch (category) {
      case PictogramCategory.eten:
        return [
          'eten', 'drinken', 'voedsel', 'maaltijd', 'ontbijt', 'lunch', 'diner',
          'vlees', 'vis', 'zeevruchten', 'zuivel', 'ei', 'eiproduct',
          'fruit', 'groente', 'gedroogd fruit', 'peulvrucht', 'graan', 'kruiden', 'aromatische kruiden',
          'vleeswaren', 'dessert', 'bakken', 'snoep', 'condiment',
          'drank', 'beverage', 'gastronomie', 'traditioneel gerecht', 'smaak', 'koken', 'kookkunst'
        ];
      case PictogramCategory.vrijetijd:
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
        return [
          'plaats', 'locatie', 'monument', 'gebouw', 'woongebouw', 'kamer', 'room',
          'commercieel gebouw', 'cultureel gebouw', 'horeca', 'religieus gebouw',
          'gebouwsfaciliteit', 'industrieel gebouw', 'onderwijsgebouw', 'medisch centrum',
          'gebouwskamer', 'openbaar gebouw', 'dienstgebouw', 'faciliteit', 'recreatiefaciliteit',
          'speeltuin', 'recyclingcentrum', 'stedelijk gebied', 'straatmeubilair',
          'infrastructuur', 'werkplek', 'landelijk gebied'
        ];
      case PictogramCategory.onderwijs:
        return [
          'onderwijs', 'school', 'leren', 'leraar', 'leerling', 'klas', 'les',
          'onderwijsactiviteit', 'vak', 'onderwijsinstelling', 'onderwijstaak',
          'onderwijsmateriaal', 'onderwijsapparatuur', 'onderwijsruimte',
          'onderwijsorganisatie', 'onderwijsinstelling', 'speciaal onderwijs',
          'onderwijspersoneel', 'onderwijsdocumentatie', 'studenten', 'onderwijsmethodologie'
        ];
      case PictogramCategory.tijd:
        return [
          'tijd', 'uur', 'dag', 'week', 'maand', 'jaar', 'moment',
          'chronologische tijd', 'evenement', 'populair evenement', 'halloween', 'carnaval',
          'nieuwjaar', 'fiestas del pilar', 'populair festival', 'kerstmis', 'paasweek',
          'religieus evenement', 'sociaal evenement', 'verjaardag', 'bruiloft', 'dood',
          'oorlog', 'kalender', 'seizoen', 'dagtijd', 'tijdeenheid', 'daguren',
          'chronologisch instrument'
        ];
      case PictogramCategory.diversen:
        return [
          'diversen', 'overig', 'anders', 'miscellaneous',
          'covid-19', 'categorisatie', 'internationale organisatie', 'seizoenen',
          'winter', 'zomer', 'herfst', 'lente', 'aragon', 'huesca', 'teruel', 'zaragoza',
          'orofaciale praxis'
        ];
      case PictogramCategory.beweging:
        return [
          'beweging', 'lopen', 'rennen', 'gaan', 'reizen', 'verplaatsen',
          'verkeer', 'verkeersveiligheid', 'verkeerslicht', 'vervoermiddel',
          'watertransport', 'luchttransport', 'landtransport', 'voertuigonderdeel',
          'route', 'verkeersongeval'
        ];
      case PictogramCategory.religie:
        return [
          'religie', 'geloof', 'kerk', 'bidden', 'aanbidden',
          'christendom', 'islam', 'jodendom', 'boeddhisme', 'hindoeïsme',
          'religieus object', 'religieuze plaats', 'religieus persoon',
          'religieus karakter', 'religieuze handeling'
        ];
      case PictogramCategory.werk:
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
        return [
          'document', 'papier', 'brief', 'bestand', 'formulier', 'briefje',
          'medische documentatie', 'ondersteunend document', 'officieel document',
          'onderwijsdocument', 'informatiedocument', 'gerechtelijk document',
          'handelsdocument', 'kernwoordenschat'
        ];
      case PictogramCategory.kennis:
        return [
          'kennis', 'informatie', 'leren', 'begrijpen', 'weten',
          'kunst', 'wetenschap', 'geesteswetenschappen', 'kernwoordenschat'
        ];
      case PictogramCategory.object:
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
        return [
          'dier', 'mens', 'persoon', 'huisdier', 'hond', 'kat', 'dieren',
          'levend wezen', 'dierlijk', 'mensen', 'persoonlijk'
        ];
      case PictogramCategory.gevoelens:
        return [
          'gevoel', 'emotie', 'blij', 'verdrietig', 'boos', 'liefde', 'gelukkig',
          'gevoelens', 'emoties'
        ];
      case PictogramCategory.gezondheid:
        return [
          'gezondheid', 'medicijn', 'dokter', 'ziekenhuis', 'medisch', 'geneeskunde',
          'gezondheidszorg', 'medicatie'
        ];
      case PictogramCategory.lichaam:
        return [
          'lichaam', 'hoofd', 'hand', 'voet', 'oog', 'oor', 'mond', 'gezicht', 'lichaamsdeel',
          'lichaamsdelen'
        ];
    }
  }

  /// Search pictograms by category with pagination support
  /// Uses the same category keywords for consistent results
  Future<List<Pictogram>> searchPictograms({
    required PictogramCategory category,
    String? keyword,
    int limit = _defaultLimit,
    int offset = 0,
  }) async {
    // Single keyword search - no pagination needed
    if (keyword != null && keyword.isNotEmpty) {
      return await _singleKeywordSearch(category, keyword, limit);
    }

    try {
      // Get category search terms (same keywords for each category)
      final searchTerms = _getCategorySearchTerms(category);
      final mergedResults = <Pictogram>[];
      final seenIds = <int>{};
      int apiCallCount = 0;

      // Process up to 50 terms per search
      final termsToProcess = searchTerms.length > 50
          ? searchTerms.take(50).toList()
          : searchTerms;

      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Fetching page offset=$offset, limit=$limit using ${termsToProcess.length} terms');
      }

      // Collect results from all terms first (for proper pagination)
      for (final term in termsToProcess) {
        if (apiCallCount >= _maxApiCallsPerCategory) {
          if (kDebugMode) {
            debugPrint('Category search [${category.key}]: Reached API call limit ($_maxApiCallsPerCategory)');
          }
          break;
        }

        try {
          final encodedQuery = Uri.encodeComponent(term);
          final url = _buildSearchUrl(encodedQuery, language: 'nl');

          final response = await http.get(url).timeout(
            _requestTimeout,
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

          apiCallCount++;

          if (response.statusCode == 200) {
            // Fetch enough results to support pagination
            // Request more than needed to account for duplicates
            final termResults = _parseSearchResponse(
              response.body,
              category,
              100, // Request max per term
            );

            // Add unique results
            for (var pictogram in termResults) {
              if (!seenIds.contains(pictogram.id)) {
                seenIds.add(pictogram.id);
                mergedResults.add(pictogram);
              }
            }

            // Stop early if we have enough for the requested page + some buffer
            if (mergedResults.length >= (offset + limit + 50)) {
              if (kDebugMode) {
                debugPrint('Category search [${category.key}]: Collected ${mergedResults.length} total results, enough for pagination');
              }
              break;
            }
          }
        } on SocketException {
          continue;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Category search [${category.key}]: Error searching term "$term": $e');
          }
          continue;
        }
      }

      // Apply pagination to merged results
      var finalResults = mergedResults.skip(offset).take(limit).toList();

      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Returned ${finalResults.length} results (page offset=$offset, limit=$limit)');
      }

      // Fallback if results are too few
      if (finalResults.length <= 2) {
        final fallbackResults = await _tryFallbackSearches(category, limit, finalResults.length);

        if (fallbackResults.isNotEmpty && finalResults.length <= 2) {
          final combined = <Pictogram>[...finalResults];

          for (var result in fallbackResults) {
            if (combined.length >= limit) break;
            if (!combined.any((p) => p.id == result.id)) {
              combined.add(result);
            }
          }

          if (kDebugMode && combined.length > finalResults.length) {
            debugPrint('Category search [${category.key}]: Added ${combined.length - finalResults.length} pictograms from fallback');
          }

          return combined;
        }
      }

      // Add custom pictograms
      try {
        final customPictograms = await _customPictogramService.getCustomPictogramsByCategory(category.key);
        if (customPictograms.isNotEmpty) {
          finalResults.addAll(customPictograms);
          if (kDebugMode) {
            debugPrint('Category search [${category.key}]: Added ${customPictograms.length} custom pictograms');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Category search [${category.key}]: Error loading custom pictograms: $e');
        }
      }

      return finalResults;
    } on SocketException {
      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Offline - cannot search pictograms');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Category search [${category.key}]: Error in multi-keyword search: $e');
      }

      try {
        return await _tryBroaderSearch(category, limit);
      } catch (_) {
        return [];
      }
    }
  }

  /// Get cached pictograms with pagination support for offline mode
  /// Uses same category keywords to filter cached items
  /// Attempts to enhance keywords if online
  Future<List<Pictogram>> getCachedPictogramsWithPagination({
    String? category,
    int limit = _defaultLimit,
    int offset = 0,
    bool enhanceKeywords = true,
  }) async {
    // Offline pictogram cache has been removed. Always return an empty list.
    return [];
  }

  /// Enhance cached pictogram keywords by fetching from API if online
  /// Only enhances pictograms that have fallback keywords or truncated keywords
  Future<List<Pictogram>> _enhanceCachedPictogramKeywords(List<Pictogram> pictograms) async {
    final fallbackKeywords = ['Opgeslagen pictogram', 'Saved pictogram', 'Onbekend'];
    final enhancedPictograms = <Pictogram>[];
    
    for (final pictogram in pictograms) {
      // Check if keyword is a fallback or truncated version
      final isFallback = fallbackKeywords.contains(pictogram.keyword) ||
                         pictogram.keyword.startsWith('Opgeslag') ||
                         pictogram.keyword.startsWith('Opgeslagen') ||
                         pictogram.keyword.startsWith('Saved') ||
                         pictogram.keyword.startsWith('Pictogram ') ||
                         pictogram.keyword.contains('picto') ||
                         (pictogram.keyword.length < 3 && pictogram.keyword.isNotEmpty);
      
      // Skip if keyword is already valid (not a fallback)
      if (!isFallback && pictogram.keyword.isNotEmpty) {
        enhancedPictograms.add(pictogram);
        continue;
      }
      
      // Try to fetch real keyword from API (quick timeout to avoid blocking)
      if (pictogram.id > 0) {
        try {
          final fetched = await getPictogramById(pictogram.id).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
          
          if (fetched != null && 
              fetched.keyword.isNotEmpty && 
              !fallbackKeywords.contains(fetched.keyword) &&
              !fetched.keyword.startsWith('Opgeslag') &&
              !fetched.keyword.startsWith('Saved')) {
            // Update metadata with real keyword
            try {
              final metadata = await _loadCacheMetadata();
              final category = pictogram.category;
              metadata[pictogram.id] = '$category|${fetched.keyword}';
              await _saveCacheMetadata(metadata);
              
              if (kDebugMode) {
                debugPrint('Enhanced keyword for pictogram ${pictogram.id}: "${pictogram.keyword}" -> "${fetched.keyword}"');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error updating metadata for enhanced keyword: $e');
              }
            }
            
            // Use enhanced pictogram with real keyword
            enhancedPictograms.add(pictogram.copyWith(
              keyword: fetched.keyword,
            ));
            continue;
          }
        } catch (e) {
          // Network error or timeout - keep original
          if (kDebugMode) {
            debugPrint('Could not enhance keyword for pictogram ${pictogram.id}: $e');
          }
        }
      }
      
      // Keep original if enhancement failed or not needed
      enhancedPictograms.add(pictogram);
    }
    
    return enhancedPictograms;
  }

  Future<List<Pictogram>> _singleKeywordSearch(
    PictogramCategory category,
    String keyword,
    int limit,
  ) async {
    try {
      final encodedQuery = Uri.encodeComponent(keyword.toLowerCase().trim());
      final url = _buildSearchUrl(encodedQuery, language: 'nl');

      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final results = _parseSearchResponse(response.body, category, limit);

        return results;
      }
    } on SocketException {
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

  Future<Pictogram?> getPictogramById(int pictogramId) async {
    try {
      final urls = [
        Uri.parse('$_baseUrl/pictograms/$pictogramId?download=false&url=true&locale=nl'),
        Uri.parse('$_baseUrl/pictograms/$pictogramId?download=false&url=true&locale=en'),
        Uri.parse('$_baseUrl/pictograms/$pictogramId?download=false&url=true'),
        Uri.parse('$_baseUrl/pictograms/$pictogramId?locale=nl'),
        Uri.parse('$_baseUrl/pictograms/$pictogramId?locale=en'),
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
            final contentType = response.headers['content-type'] ?? '';
            final bodyBytes = response.bodyBytes;

            if (bodyBytes.length >= 4) {
              final pngSignature = [0x89, 0x50, 0x4E, 0x47];
              final isPng = bodyBytes[0] == pngSignature[0] &&
                           bodyBytes[1] == pngSignature[1] &&
                           bodyBytes[2] == pngSignature[2] &&
                           bodyBytes[3] == pngSignature[3];

              if (isPng) {
                continue;
              }
            }

            if (contentType.contains('application/json') ||
                contentType.contains('text/json') ||
                contentType.isEmpty) {
              try {
                final dynamic decoded = json.decode(response.body);
                if (decoded is Map) {
                  final keyword = _extractKeyword(decoded);
                  if (keyword.isNotEmpty && keyword != 'Onbekend') {
                    return Pictogram(
                      id: pictogramId,
                      keyword: keyword,
                      category: 'fetched',
                      imageUrl: getStaticImageUrl(pictogramId),
                      description: _extractDescription(decoded),
                    );
                  }
                }
              } catch (jsonError) {
                continue;
              }
            } else {
              continue;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            if (e is! FormatException) {
              debugPrint('Error fetching from $url: $e');
            }
          }
          continue;
        }
      }
    } on SocketException {
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

  Future<List<Pictogram>> searchByKeyword(String keyword, {int limit = _defaultLimit}) async {
    try {
      final encodedQuery = Uri.encodeComponent(keyword.toLowerCase().trim());
      final url = _buildSearchUrl(encodedQuery, language: 'nl');

      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final category = PictogramCategory.diversen;
        final results = _parseSearchResponse(response.body, category, limit);

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
          if (kDebugMode) {
            debugPrint('Keyword search: Error loading custom pictograms: $e');
          }
        }

        return results;
      }
    } on SocketException {
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

  Uri _buildSearchUrl(String encodedQuery, {String? language}) {
    final lang = language ?? _language;
    return Uri.parse('$_baseUrl/pictograms/$lang/search/$encodedQuery');
  }

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

  Pictogram? _parsePictogramItem(dynamic item, PictogramCategory category) {
    try {
      if (item is! Map) {
        return null;
      }

      final id = _extractPictogramId(item);
      if (id <= 0) {
        return null;
      }

      final keyword = _extractKeyword(item);

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

  int _extractPictogramId(Map<dynamic, dynamic> item) {
    dynamic idValue = item['_id'] ?? item['id'];

    if (idValue is int) {
      return idValue;
    } else if (idValue is String) {
      return int.tryParse(idValue) ?? 0;
    }

    return 0;
  }

  String getLocalizedKeyword(List<dynamic> keywords) {
    if (keywords.isEmpty) {
      return 'Onbekend';
    }

    String? dutchKeyword;
    String? englishKeyword;
    String? anyKeyword;

    for (var k in keywords) {
      if (k is Map) {
        final keywordText = (k['keyword'] as String?) ??
                           (k['text'] as String?) ??
                           (k['name'] as String?);
        final locale = (k['locale'] as String?) ??
                      (k['language'] as String?) ??
                      (k['lang'] as String?);

        if (keywordText != null && keywordText.trim().isNotEmpty) {
          final trimmedKeyword = keywordText.trim();
          if ((locale == 'nl' || locale == 'dutch' || locale == 'nederlands') && dutchKeyword == null) {
            dutchKeyword = trimmedKeyword;
          }
          else if ((locale == 'en' || locale == 'english' || locale == 'engels') && englishKeyword == null) {
            englishKeyword = trimmedKeyword;
          }
          anyKeyword ??= trimmedKeyword;

          if (dutchKeyword != null) {
            break;
          }
        }
      } else if (k is String) {
        if (anyKeyword == null && k.trim().isNotEmpty) {
          anyKeyword = k.trim();
        }
      }
    }

    return dutchKeyword ?? englishKeyword ?? anyKeyword ?? 'Onbekend';
  }

  String _extractKeyword(Map<dynamic, dynamic> item) {
    final keywords = item['keywords'] as List<dynamic>?;

    if (keywords != null && keywords.isNotEmpty) {
      final localizedKeyword = getLocalizedKeyword(keywords);
      if (localizedKeyword != 'Onbekend') {
        return localizedKeyword;
      }
    }

    final directKeyword = item['keyword'] as String?;
    if (directKeyword != null && directKeyword.trim().isNotEmpty) {
      return directKeyword.trim();
    }

    final name = item['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final text = item['text'] as String?;
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }

    final description = item['description'] as String?;
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }

    return 'Onbekend';
  }

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

  Future<List<Pictogram>> _tryFallbackSearches(
    PictogramCategory originalCategory,
    int limit,
    int currentCount,
  ) async {
    if (currentCount > 2) {
      return [];
    }

    final fallbackResults = <Pictogram>[];
    final seenIds = <int>{};

    final dailyActivityCategories = [
      PictogramCategory.eten,
      PictogramCategory.beweging,
      PictogramCategory.tijd,
    ];

    final personalCareCategories = [
      PictogramCategory.lichaam,
      PictogramCategory.gezondheid,
    ];

    for (var fallbackCategory in dailyActivityCategories) {
      if (fallbackCategory == originalCategory) continue;

      try {
        final searchTerms = _getCategorySearchTerms(fallbackCategory);

        for (final term in searchTerms.take(3)) {
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

            for (var pictogram in pictograms) {
              if (!seenIds.contains(pictogram.id)) {
                seenIds.add(pictogram.id);
                fallbackResults.add(pictogram);
                if (fallbackResults.length >= 40) break;
              }
            }

            if (kDebugMode && pictograms.isNotEmpty) {
              debugPrint('Fallback search: Found ${pictograms.length} pictograms in ${fallbackCategory.key}');
            }
          }

          if (fallbackResults.length >= 40) break;
        }
      } on SocketException {
        continue;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in fallback search for ${fallbackCategory.key}: $e');
        }
        continue;
      }

      if (fallbackResults.length >= 40) break;
    }

    if (fallbackResults.length < 40) {
      for (var fallbackCategory in personalCareCategories) {
        if (fallbackCategory == originalCategory) continue;

        try {
          final searchTerms = _getCategorySearchTerms(fallbackCategory);

          for (final term in searchTerms.take(3)) {
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

              for (var pictogram in pictograms) {
                if (!seenIds.contains(pictogram.id)) {
                  seenIds.add(pictogram.id);
                  fallbackResults.add(pictogram);
                  if (fallbackResults.length >= 40) break;
                }
              }

              if (kDebugMode && pictograms.isNotEmpty) {
                debugPrint('Fallback search: Found ${pictograms.length} pictograms in ${fallbackCategory.key}');
              }
            }

            if (fallbackResults.length >= 40) break;
          }
        } on SocketException {
          continue;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error in fallback search for ${fallbackCategory.key}: $e');
          }
          continue;
        }

        if (fallbackResults.length >= 40) break;
      }
    }

    return fallbackResults;
  }

  Future<List<Pictogram>> _tryBroaderSearch(
    PictogramCategory category,
    int limit,
  ) async {
    try {
      final broadTerm = category.searchTerm;
      final encodedQuery = Uri.encodeComponent(broadTerm);
      final url = _buildSearchUrl(encodedQuery, language: _categorySearchLanguage);

      final response = await http.get(url).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final results = _parseSearchResponse(response.body, category, limit);

        return results;
      }
    } on SocketException {
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

  String getImageUrl(int pictogramId) {
    return '$_baseUrl/pictograms/$pictogramId?download=false&url=true';
  }

  String getStaticImageUrl(int pictogramId) {
    return getStaticImageUrlWithSize(pictogramId, size: 5000);
  }

  String getStaticImageUrlWithSize(int pictogramId, {int size = 5000}) {
    if (CustomPictogramService.isCustomPictogram(pictogramId)) {
      return '';
    }

    return '$_imageBaseUrl/$pictogramId/${pictogramId}_$size.png';
  }

  String getThumbnailUrl(int pictogramId) {
    if (CustomPictogramService.isCustomPictogram(pictogramId)) {
      return '';
    }
    return getStaticImageUrlWithSize(pictogramId, size: 500);
  }

  String getPreviewUrl(int pictogramId) {
    return getStaticImageUrlWithSize(pictogramId, size: 1000);
  }

  String getBestQualityImageUrl(int pictogramId) {
    return getStaticImageUrl(pictogramId);
  }

  List<String> getImageUrlAlternatives(int pictogramId) {
    return [
      getStaticImageUrlWithSize(pictogramId, size: 5000),
      '$_imageBaseUrl/$pictogramId/$pictogramId.png',
      getImageUrl(pictogramId),
    ];
  }

  String getAttributionText() {
    return 'Pictograms by ARASAAC (${getAttributionUrl()}), used under CC BY-NC-SA license';
  }

  String getAttributionUrl() {
    return 'https://arasaac.org';
  }
}
