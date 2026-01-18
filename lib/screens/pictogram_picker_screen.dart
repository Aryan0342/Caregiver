import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pictogram_model.dart';
import '../services/arasaac_service.dart';
import '../theme.dart';
import '../providers/language_provider.dart';

class PictogramPickerScreen extends StatefulWidget {
  final List<Pictogram>? initialSelection;
  final int maxSelection;

  const PictogramPickerScreen({
    super.key,
    this.initialSelection,
    this.maxSelection = 10,
  });

  @override
  State<PictogramPickerScreen> createState() => _PictogramPickerScreenState();
}

class _PictogramPickerScreenState extends State<PictogramPickerScreen> {
  final ArasaacService _arasaacService = ArasaacService();
  final Map<PictogramCategory, List<Pictogram>> _pictogramsByCategory = {};
  final Map<PictogramCategory, bool> _isOnlineByCategory = {}; // Track online/offline state per category
  final Set<Pictogram> _selectedPictograms = {};
  PictogramCategory _selectedCategory = PictogramCategory.eten; // Start with Feeding category
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<Pictogram> _searchResults = [];
  bool _isSearching = false;
  static const int _initialLoadCount = 18; // 3 columns × 6 rows = 18 pictograms (fits one screen)
  static const int _loadMoreCount = 18; // Load 18 more each time

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedPictograms.addAll(widget.initialSelection!);
    }
    _loadPictograms(_selectedCategory);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final results = await _arasaacService.searchByKeyword(query, limit: 100);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fout bij zoeken. Probeer het opnieuw.';
        _isLoading = false;
      });
    }
  }

  /// Load pictograms for a category - handles both online and offline modes with pagination
  Future<void> _loadPictograms(PictogramCategory category, {bool loadMore = false}) async {
    final currentPictograms = _pictogramsByCategory[category] ?? [];
    final isOnline = _isOnlineByCategory[category] ?? true; // Assume online by default
    final currentOffset = loadMore ? currentPictograms.length : 0;

    if (loadMore) {
      // Loading more pictograms
      setState(() {
        _isLoadingMore = true;
      });

      try {
        List<Pictogram> morePictograms;

        if (isOnline) {
          // Online mode: fetch from API with pagination
          morePictograms = await _arasaacService.searchPictograms(
            category: category,
            limit: _loadMoreCount,
            offset: currentOffset,
          ).timeout(const Duration(seconds: 30), onTimeout: () {
            if (kDebugMode) {
              debugPrint('searchPictograms timed out - switching to offline mode');
            }
            return <Pictogram>[];
          });

          if (morePictograms.isEmpty) {
            // API returned empty - check if we're actually offline
            throw SocketException('No results from API');
          }

          // Cache newly loaded pictograms
          _precachePictograms(morePictograms, category.key);
        } else {
          // Offline mode: load from cache with pagination
          // Try to enhance keywords if we might be online
          bool mightBeOnline = false;
          try {
            final testResult = await _arasaacService.getPictogramById(1).timeout(
              const Duration(seconds: 1),
              onTimeout: () => null,
            );
            mightBeOnline = testResult != null;
          } catch (e) {
            mightBeOnline = false;
          }
          
          morePictograms = await _arasaacService.getCachedPictogramsWithPagination(
            category: category.key,
            limit: _loadMoreCount,
            offset: currentOffset,
            enhanceKeywords: mightBeOnline, // Enhance if online
          );
        }

        if (morePictograms.isEmpty) {
          // No more pictograms available
          setState(() {
            _isLoadingMore = false;
          });
          return;
        }

        // Add to existing list
        setState(() {
          _pictogramsByCategory[category] = [...currentPictograms, ...morePictograms];
          _isLoadingMore = false;
        });
      } catch (e) {
        if (e is SocketException || e is TimeoutException) {
          // Network error - switch to offline mode and try cache
          if (isOnline) {
            debugPrint('Network error, switching to offline mode for category ${category.key}');
            setState(() {
              _isOnlineByCategory[category] = false;
              _isLoadingMore = false;
            });
            // Retry in offline mode
            return _loadPictograms(category, loadMore: true);
          }
        }

        setState(() {
          _isLoadingMore = false;
        });
        debugPrint('Error loading more pictograms: $e');
      }
      return;
    }

    // Initial load
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try online first
      debugPrint('Attempting to fetch pictograms for category ${category.key} (online mode)...');
      final pictograms = await _arasaacService.searchPictograms(
        category: category,
        limit: _initialLoadCount,
        offset: 0,
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        if (kDebugMode) {
          debugPrint('searchPictograms timed out after 30 seconds');
        }
        return <Pictogram>[];
      });

      if (pictograms.isNotEmpty) {
        // Online mode: successfully fetched from API
        // Enhance keywords for any pictograms that might have fallback/truncated keywords
        final enhancedPictograms = await _enhancePictogramKeywords(pictograms);
        
        debugPrint('Online mode: Successfully fetched ${enhancedPictograms.length} pictograms for category ${category.key}');
        setState(() {
          _pictogramsByCategory[category] = enhancedPictograms;
          _isOnlineByCategory[category] = true;
          _isLoading = false;
        });

        // Cache pictograms in background for offline use (with correct keywords)
        _precachePictograms(enhancedPictograms, category.key);
        return;
      }

      // Empty result or timeout - try offline mode
      throw SocketException('No results from API');
    } on SocketException catch (e) {
      // Offline - load from cache
      debugPrint('SocketException caught, loading cached pictograms for category ${category.key}: $e');
      await _loadOfflinePictograms(category);
    } catch (e) {
      // Other error - try offline as fallback
      debugPrint('Error loading pictograms: $e, trying offline mode...');
      await _loadOfflinePictograms(category);
    }
  }

  /// Load pictograms from cache (offline mode) with pagination support
  /// Also enhances keywords if online
  Future<void> _loadOfflinePictograms(PictogramCategory category) async {
    try {
      // First load cached pictograms (might have bad keywords in metadata)
      var cachedPictograms = await _arasaacService.getCachedPictogramsWithPagination(
        category: category.key,
        limit: _initialLoadCount,
        offset: 0,
        enhanceKeywords: false, // Don't enhance yet - check online status first
      );

      if (cachedPictograms.isEmpty) {
        debugPrint('No cached pictograms found for category ${category.key}');
        setState(() {
          _errorMessage = 'Offline modus: Geen pictogrammen beschikbaar. Verbind met internet om nieuwe pictogrammen te zoeken.';
          _isOnlineByCategory[category] = false;
          _isLoading = false;
        });
        return;
      }

      // Check if we're actually online (maybe API failed but network is available)
      bool mightBeOnline = false;
      try {
        // Quick test to see if we can reach API with a simple pictogram ID
        final testResult = await _arasaacService.getPictogramById(1).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        mightBeOnline = testResult != null;
      } catch (e) {
        mightBeOnline = false;
      }

      // If online, try to enhance keywords
      if (mightBeOnline) {
        debugPrint('Online detected, enhancing keywords for ${cachedPictograms.length} cached pictograms...');
        cachedPictograms = await _arasaacService.getCachedPictogramsWithPagination(
          category: category.key,
          limit: _initialLoadCount,
          offset: 0,
          enhanceKeywords: true, // Enhance keywords now that we know we're online
        );
      }

      debugPrint('${mightBeOnline ? "Online" : "Offline"} mode: Loaded ${cachedPictograms.length} cached pictograms for category ${category.key}');
      setState(() {
        _pictogramsByCategory[category] = cachedPictograms;
        _isOnlineByCategory[category] = mightBeOnline;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cached pictograms: $e');
      setState(() {
        _errorMessage = 'Fout bij laden van pictogrammen: ${e.toString()}';
        _isOnlineByCategory[category] = false;
        _isLoading = false;
      });
    }
  }


  /// Enhance pictogram keywords by fetching from API if needed
  Future<List<Pictogram>> _enhancePictogramKeywords(List<Pictogram> pictograms) async {
    final enhanced = <Pictogram>[];
    
    for (final pictogram in pictograms) {
      // Check if keyword needs enhancement (fallback or truncated)
      final needsEnhancement = pictogram.keyword.isEmpty ||
                               pictogram.keyword == 'Opgeslagen pictogram' ||
                               pictogram.keyword == 'Saved pictogram' ||
                               pictogram.keyword == 'Onbekend' ||
                               pictogram.keyword.startsWith('Opgeslag') ||
                               pictogram.keyword.startsWith('Saved') ||
                               pictogram.keyword.contains('picto') ||
                               pictogram.keyword.startsWith('Pictogram ');
      
      if (!needsEnhancement || pictogram.id <= 0) {
        enhanced.add(pictogram);
        continue;
      }
      
      // Try to fetch real keyword
      try {
        final fetched = await _arasaacService.getPictogramById(pictogram.id).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        
        if (fetched != null && 
            fetched.keyword.isNotEmpty && 
            fetched.keyword != 'Opgeslagen pictogram' &&
            fetched.keyword != 'Saved pictogram' &&
            !fetched.keyword.startsWith('Opgeslag')) {
          enhanced.add(pictogram.copyWith(keyword: fetched.keyword));
          debugPrint('Enhanced keyword for pictogram ${pictogram.id}: "${pictogram.keyword}" -> "${fetched.keyword}"');
        } else {
          enhanced.add(pictogram);
        }
      } catch (e) {
        // Keep original on error
        enhanced.add(pictogram);
      }
    }
    
    return enhanced;
  }

  /// Pre-cache pictogram images in the background for offline use
  /// Caches pictograms as they are loaded (no arbitrary limit)
  Future<void> _precachePictograms(List<Pictogram> pictograms, String categoryKey) async {
    // Only cache ARASAAC pictograms (not custom ones)
    final arasaacPictograms = pictograms.where((p) => p.id > 0).toList();
    
    if (arasaacPictograms.isEmpty) {
      return;
    }
    
    debugPrint('Pre-caching ${arasaacPictograms.length} pictograms for category $categoryKey...');
    int cachedCount = 0;
    int errorCount = 0;
    
    // Cache in smaller batches to avoid overwhelming the network
    const batchSize = 10;
    for (int i = 0; i < arasaacPictograms.length; i += batchSize) {
      final batch = arasaacPictograms.skip(i).take(batchSize).toList();
      
      // Process batch in parallel
      await Future.wait(
        batch.map((pictogram) async {
          try {
            // Download and cache (will skip if already cached)
            // Pass keyword so it's stored in metadata for offline display
            final cached = await _arasaacService.downloadAndCachePictogramAtSize(
              pictogram.id,
              size: 500,
              category: categoryKey,
              keyword: pictogram.keyword, // Store keyword for offline use
            );
            if (cached != null) {
              cachedCount++;
            } else {
              errorCount++;
            }
          } catch (e) {
            errorCount++;
            debugPrint('Error pre-caching pictogram ${pictogram.id}: $e');
          }
        }),
      );
      
      // Small delay between batches to avoid rate limiting
      if (i + batchSize < arasaacPictograms.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    debugPrint('Pre-caching complete: $cachedCount cached, $errorCount errors for category $categoryKey');
  }

  /// Cache image to custom directory when displayed (called for each pictogram in grid)
  void _cacheImageToCustomDirectory(int pictogramId, String category, String keyword) {
    // Always download and cache with category and keyword
    // This ensures we always have the latest version and update metadata
    _arasaacService.downloadAndCachePictogram(pictogramId, category: category, keyword: keyword).then((file) {
      if (file != null) {
        if (kDebugMode) {
          debugPrint('Successfully cached pictogram $pictogramId to custom directory');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Failed to cache pictogram $pictogramId (returned null)');
        }
      }
    }).catchError((e) {
      if (kDebugMode) {
        debugPrint('Error caching pictogram $pictogramId: $e');
      }
    });
  }

  void _toggleSelection(Pictogram pictogram) {
    setState(() {
      if (_selectedPictograms.contains(pictogram)) {
        _selectedPictograms.remove(pictogram);
      } else {
        if (_selectedPictograms.length < widget.maxSelection) {
          _selectedPictograms.add(pictogram);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${widget.maxSelection} pictogrammen geselecteerd',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    });
  }

  void _onCategoryChanged(PictogramCategory category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _isSearching = false;
      _searchResults = [];
    });
    // Load pictograms for the new category
    _loadPictograms(category);
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedPictograms.toList());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    // Show search results if searching, otherwise show category pictograms
    final currentPictograms = _isSearching 
        ? _searchResults 
        : (_pictogramsByCategory[_selectedCategory] ?? []);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.choosePictograms),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPictograms.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                '${localizations.done} (${_selectedPictograms.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizations.searchPictograms,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _isSearching = false;
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // Category tabs
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: PictogramCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(localizations.getCategoryName(category.key)),
                    selected: isSelected,
                    onSelected: (_) => _onCategoryChanged(category),
                    selectedColor: AppTheme.primaryBlue,
                    backgroundColor: AppTheme.primaryBlueLight,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : AppTheme.primaryBlue.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Pictogram grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadPictograms(_selectedCategory),
                              child: const Text('Opnieuw proberen'),
                            ),
                          ],
                        ),
                      )
                    : currentPictograms.isEmpty
                        ? Center(
                            child: Text(
                              'Geen pictogrammen gevonden',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.9,
                                  ),
                                  itemCount: currentPictograms.length,
                                  itemBuilder: (context, index) {
                                    final pictogram = currentPictograms[index];
                                    final isSelected = _selectedPictograms.contains(pictogram);

                                    return _buildPictogramCard(pictogram, isSelected);
                                  },
                                ),
                              ),
                              // Load More button - always show if we have initial load, show loader when loading more
                              if (_shouldShowLoadMoreButton() || _isLoadingMore)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: _isLoadingMore
                                      ? ElevatedButton.icon(
                                          onPressed: null, // Disabled while loading
                                          icon: const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          label: Text(
                                            'Laden...',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.7),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.7),
                                          ),
                                        )
                                      : ElevatedButton.icon(
                                          onPressed: () => _loadPictograms(_selectedCategory, loadMore: true),
                                          icon: const Icon(Icons.expand_more),
                                          label: Text(
                                            'Laad meer pictogrammen',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlue,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPictogramCard(Pictogram pictogram, bool isSelected) {
    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleSelection(pictogram),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Pictogram image
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildPictogramImage(pictogram),
                  ),
                  const SizedBox(height: 4),
                  // Keyword label - always displays localized Dutch keyword from model
                  // (not the search query entered by user)
                  Text(
                    pictogram.keyword,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictogramImage(Pictogram pictogram) {
    // Check if this is a local file path (offline cached pictogram)
    // Windows paths can start with drive letters (C:\), Unix paths start with /
    // Also check for absolute paths that don't start with http/https
    final isLocalPath = pictogram.imageUrl.startsWith('/') || 
                        pictogram.imageUrl.startsWith('file://') ||
                        (pictogram.imageUrl.length > 1 && pictogram.imageUrl[1] == ':') ||
                        (!pictogram.imageUrl.startsWith('http://') && 
                         !pictogram.imageUrl.startsWith('https://') &&
                         pictogram.imageUrl.contains(Platform.pathSeparator));
    
    if (isLocalPath) {
      // Local file path - use Image.file for offline cached pictograms
      String filePath = pictogram.imageUrl;
      // Remove file:// prefix if present
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7); // Remove 'file://' prefix
      }
      
      debugPrint('Loading cached pictogram from local path: $filePath');
      
      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('Cached file does not exist: $filePath');
        return _buildFallbackIcon(_getIconForKeyword(pictogram.keyword));
      }
      
      return Image.file(
        file,
        fit: BoxFit.contain,
        cacheWidth: 300, // Optimize memory usage
        cacheHeight: 300,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading cached image file: $error');
          return _buildFallbackIcon(_getIconForKeyword(pictogram.keyword));
        },
      );
    }
    
    // For custom pictograms, use the imageUrl from the model (Firebase Storage URL)
    // For ARASAAC pictograms, use smaller size (300px) for faster grid loading
    final imageUrl = pictogram.imageUrl.isNotEmpty && pictogram.id < 0
        ? pictogram.imageUrl // Custom pictogram - use stored Firebase Storage URL
        : _arasaacService.getStaticImageUrlWithSize(pictogram.id, size: 300); // ARASAAC pictogram - use 300px for speed
    final fallbackIcon = _getIconForKeyword(pictogram.keyword);
    
    // Use smaller image size (300px) for faster loading in grid view
    // Only use thumbnail URL - no fallbacks to speed up loading
    // Also cache to our custom directory when image loads
    if (pictogram.id > 0) {
      // ARASAAC pictogram - cache it when displayed with category and keyword
      _cacheImageToCustomDirectory(pictogram.id, pictogram.category, pictogram.keyword);
    }
    
    return CachedNetworkImage(
      imageUrl: imageUrl.isEmpty ? _arasaacService.getStaticImageUrlWithSize(pictogram.id, size: 300) : imageUrl,
      // Optimize cache for grid thumbnails (300px for faster loading)
      maxWidthDiskCache: 300,
      maxHeightDiskCache: 300,
      memCacheWidth: 200,
      memCacheHeight: 200,
      httpHeaders: const {
        'Accept': 'image/png,image/*;q=0.8',
        'User-Agent': 'Flutter-App',
      },
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        color: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallbackIcon(fallbackIcon),
    );
  }

  /// Check if "Load More" button should be shown
  bool _shouldShowLoadMoreButton() {
    // Don't show when searching
    if (_isSearching) {
      return false;
    }
    
    final currentPictograms = _pictogramsByCategory[_selectedCategory] ?? [];
    
    // Show button if:
    // 1. We have displayed some pictograms (at least initial load)
    // 2. We're not currently loading more
    // 3. We have at least the initial count (might be more available)
    return currentPictograms.length >= _initialLoadCount && 
           !_isLoadingMore && 
           currentPictograms.isNotEmpty;
  }

  Widget _buildFallbackIcon(IconData icon) {
    return Container(
      color: AppTheme.primaryBlueLight.withValues(alpha: 0.2),
      child: Icon(
        icon,
        color: AppTheme.primaryBlue,
        size: 50,
      ),
    );
  }

  IconData _getIconForKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    
    // Map keywords to Material icons
    if (lowerKeyword.contains('wakker') || lowerKeyword.contains('opstaan')) {
      return Icons.access_time;
    } else if (lowerKeyword.contains('aankleden') || lowerKeyword.contains('kleren')) {
      return Icons.checkroom;
    } else if (lowerKeyword.contains('ontbijt') || lowerKeyword.contains('eten')) {
      return Icons.restaurant;
    } else if (lowerKeyword.contains('tanden') || lowerKeyword.contains('poets')) {
      return Icons.cleaning_services;
    } else if (lowerKeyword.contains('school')) {
      return Icons.school;
    } else if (lowerKeyword.contains('brood')) {
      return Icons.breakfast_dining;
    } else if (lowerKeyword.contains('melk')) {
      return Icons.local_drink;
    } else if (lowerKeyword.contains('fruit')) {
      return Icons.apple;
    } else if (lowerKeyword.contains('groente')) {
      return Icons.eco;
    } else if (lowerKeyword.contains('water')) {
      return Icons.water_drop;
    } else if (lowerKeyword.contains('wassen') || lowerKeyword.contains('douche')) {
      return Icons.shower;
    } else if (lowerKeyword.contains('handen')) {
      return Icons.wash;
    } else if (lowerKeyword.contains('haar') || lowerKeyword.contains('kammen')) {
      return Icons.content_cut;
    } else if (lowerKeyword.contains('medicijn')) {
      return Icons.medication;
    } else if (lowerKeyword.contains('blij') || lowerKeyword.contains('gelukkig')) {
      return Icons.sentiment_very_satisfied;
    } else if (lowerKeyword.contains('verdriet') || lowerKeyword.contains('droevig')) {
      return Icons.sentiment_very_dissatisfied;
    } else if (lowerKeyword.contains('boos')) {
      return Icons.sentiment_dissatisfied;
    } else if (lowerKeyword.contains('bang') || lowerKeyword.contains('angst')) {
      return Icons.sentiment_very_dissatisfied;
    } else if (lowerKeyword.contains('vermoeid') || lowerKeyword.contains('moe')) {
      return Icons.bedtime;
    }
    
    // Default icon
    return Icons.image_outlined;
  }
}
