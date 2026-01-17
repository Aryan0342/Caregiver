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
  final Map<PictogramCategory, List<Pictogram>> _allPictogramsByCategory = {}; // Store all loaded pictograms
  final Map<PictogramCategory, int> _displayedCountByCategory = {}; // Track how many are displayed
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

  Future<void> _loadPictograms(PictogramCategory category, {bool loadMore = false}) async {
    // If loading more, fetch next batch from API
    if (loadMore) {
      final displayedCount = _displayedCountByCategory[category] ?? 0;
      
      setState(() {
        _isLoadingMore = true;
      });

      try {
        // Fetch next batch from API
        final morePictograms = await _arasaacService.searchPictograms(
          category: category,
          limit: _loadMoreCount,
          offset: displayedCount,
        );

        if (morePictograms.isEmpty) {
          // No more pictograms available
          setState(() {
            _isLoadingMore = false;
          });
          return;
        }

        // Add to existing list
        final currentPictograms = _pictogramsByCategory[category] ?? [];
        final allPictograms = _allPictogramsByCategory[category] ?? [];
        
        final updatedPictograms = [...currentPictograms, ...morePictograms];
        final updatedAllPictograms = [...allPictograms, ...morePictograms];
        
        setState(() {
          _allPictogramsByCategory[category] = updatedAllPictograms;
          _pictogramsByCategory[category] = updatedPictograms;
          _displayedCountByCategory[category] = updatedPictograms.length;
          _isLoadingMore = false;
        });

        // Cache only if we're still within first 50 pictograms
        if (updatedAllPictograms.length <= 50) {
          _precachePictograms(morePictograms, category.key);
        }
      } catch (e) {
        setState(() {
          _isLoadingMore = false;
        });
        debugPrint('Error loading more pictograms: $e');
      }
      
      return;
    }
    
    // Initial load - check if we already have pictograms loaded
    if (_allPictogramsByCategory.containsKey(category) && _allPictogramsByCategory[category]!.isNotEmpty) {
      // Already have pictograms, just show initial count
      final allPictograms = _allPictogramsByCategory[category]!;
      final initialCount = _initialLoadCount.clamp(0, allPictograms.length);
      setState(() {
        _pictogramsByCategory[category] = allPictograms.take(initialCount).toList();
        _displayedCountByCategory[category] = initialCount;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clear ALL cached pictograms for this category when loading in online mode
      await _arasaacService.clearCacheForCategory(category.key);
      
      // Fetch initial batch (what fits on screen)
      final pictograms = await _arasaacService.searchPictograms(
        category: category,
        limit: _initialLoadCount,
        offset: 0,
      );

      // If API returned empty list, try to load cached pictograms (might be offline)
      if (pictograms.isEmpty) {
        debugPrint('No pictograms from API, trying to load cached pictograms...');
        final cachedPictograms = await _tryLoadCachedPictograms(category);
        
        if (cachedPictograms.isNotEmpty) {
          // Use cached pictograms when offline
          debugPrint('Loaded ${cachedPictograms.length} cached pictograms');
          final initialCount = _initialLoadCount.clamp(0, cachedPictograms.length);
          setState(() {
            _allPictogramsByCategory[category] = cachedPictograms;
            _pictogramsByCategory[category] = cachedPictograms.take(initialCount).toList();
            _displayedCountByCategory[category] = initialCount;
            _isLoading = false;
          });
        } else {
          // No cached pictograms available - show offline message
          debugPrint('No cached pictograms found');
          setState(() {
            _errorMessage = 'Offline modus: Geen pictogrammen beschikbaar. Verbind met internet om nieuwe pictogrammen te zoeken.';
            _isLoading = false;
          });
        }
      } else {
        // Store pictograms and show initial count
        // Note: We only fetched 18, but there might be more available
        // So we should show "Load More" button even if we have exactly 18
        setState(() {
          _allPictogramsByCategory[category] = pictograms;
          _pictogramsByCategory[category] = pictograms;
          _displayedCountByCategory[category] = pictograms.length;
          _isLoading = false;
        });
        
        // Cache only first 50 pictograms in background for offline use (don't block UI)
        _precachePictograms(pictograms, category.key);
      }
    } on SocketException catch (e) {
      // Offline - try to load cached pictograms for this category
      debugPrint('SocketException caught, trying to load cached pictograms: $e');
      final cachedPictograms = await _tryLoadCachedPictograms(category);
      
      if (cachedPictograms.isNotEmpty) {
        debugPrint('Loaded ${cachedPictograms.length} cached pictograms after SocketException');
        final initialCount = _initialLoadCount.clamp(0, cachedPictograms.length);
        setState(() {
          _allPictogramsByCategory[category] = cachedPictograms;
          _pictogramsByCategory[category] = cachedPictograms.take(initialCount).toList();
          _displayedCountByCategory[category] = initialCount;
          _isLoading = false;
        });
      } else {
        debugPrint('No cached pictograms found after SocketException');
        setState(() {
          _errorMessage = 'Offline modus: Geen pictogrammen beschikbaar. Verbind met internet om nieuwe pictogrammen te zoeken.';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Any other error - also try to load cached pictograms as fallback
      debugPrint('Error loading pictograms: $e, trying cached pictograms as fallback...');
      final cachedPictograms = await _tryLoadCachedPictograms(category);
      
      if (cachedPictograms.isNotEmpty) {
        debugPrint('Loaded ${cachedPictograms.length} cached pictograms as fallback');
        final initialCount = _initialLoadCount.clamp(0, cachedPictograms.length);
        setState(() {
          _allPictogramsByCategory[category] = cachedPictograms;
          _pictogramsByCategory[category] = cachedPictograms.take(initialCount).toList();
          _displayedCountByCategory[category] = initialCount;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Fout bij laden van pictogrammen: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Try to load cached pictograms when offline, filtered by category
  Future<List<Pictogram>> _tryLoadCachedPictograms([PictogramCategory? category]) async {
    try {
      // Get all cached pictogram IDs from the cache directory
      final cacheDir = await _arasaacService.getCacheDirectory();
      if (cacheDir == null) {
        debugPrint('Cache directory is null');
        return [];
      }
      
      if (!await cacheDir.exists()) {
        debugPrint('Cache directory does not exist at: ${cacheDir.path}');
        return [];
      }

      debugPrint('Cache directory exists at: ${cacheDir.path}');
      
      final cachedIds = <int>[];
      int fileCount = 0;
      int dirCount = 0;
      
      try {
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            fileCount++;
            // Handle both Windows (\) and Unix (/) path separators
            final fileName = entity.path.split(Platform.pathSeparator).last;
            // Extract ID from filename (format: {id}.png)
            final match = RegExp(r'^(\d+)\.png$').firstMatch(fileName);
            if (match != null) {
              final id = int.tryParse(match.group(1)!);
              if (id != null) {
                cachedIds.add(id);
              } else {
                debugPrint('Could not parse ID from filename: $fileName');
              }
            } else {
              debugPrint('Filename does not match pattern: $fileName');
            }
          } else if (entity is Directory) {
            dirCount++;
          }
        }
      } catch (e) {
        debugPrint('Error listing cache directory: $e');
        return [];
      }

      debugPrint('Found $fileCount files and $dirCount directories in cache directory');
      debugPrint('Extracted ${cachedIds.length} valid pictogram IDs from cache');

      if (cachedIds.isEmpty) {
        debugPrint('No cached pictograms found. User needs to view pictograms online first to cache them.');
        return [];
      }

      // Get cached pictograms, filtered by category if provided
      final categoryKey = category?.key;
      debugPrint('Loading cached pictograms${categoryKey != null ? ' for category $categoryKey' : ''}...');
      final cachedPictograms = await _arasaacService.getCachedPictograms(
        ids: cachedIds.isEmpty ? null : cachedIds,
        category: categoryKey,
      );
      debugPrint('Successfully loaded ${cachedPictograms.length} cached pictograms${categoryKey != null ? ' for category $categoryKey' : ''}');
      
      if (cachedPictograms.isEmpty && cachedIds.isNotEmpty) {
        debugPrint('WARNING: Found ${cachedIds.length} cached IDs but getCachedPictograms returned empty list');
        debugPrint('First few IDs: ${cachedIds.take(5).toList()}');
      }
      
      // Enhance cached pictograms with proper keywords (they have "Pictogram {id}" by default)
      // But only if online - skip enhancement when offline to avoid spamming API
      final enhancedPictograms = <Pictogram>[];
      
      // Check if online by testing first pictogram
      bool isOnline = false;
      final firstPictogramToEnhance = cachedPictograms.firstWhere(
        (p) => p.keyword.startsWith('Pictogram ') && p.id > 0,
        orElse: () => cachedPictograms.isNotEmpty ? cachedPictograms.first : Pictogram(
          id: 0,
          keyword: '',
          category: '',
          imageUrl: '',
        ),
      );
      
      if (firstPictogramToEnhance.id > 0) {
        try {
          final testEnhanced = await _arasaacService.getPictogramById(firstPictogramToEnhance.id)
              .timeout(const Duration(seconds: 2));
          isOnline = testEnhanced != null;
        } catch (e) {
          // Network error or timeout - assume offline
          isOnline = false;
        }
      }
      
      if (!isOnline) {
        // Offline - return cached pictograms as-is without enhancement
        debugPrint('Offline mode: Skipping keyword enhancement for ${cachedPictograms.length} cached pictograms');
        return cachedPictograms;
      }
      
      // Online - enhance pictograms that need it
      for (final pictogram in cachedPictograms) {
        // If keyword is "Pictogram {id}", try to fetch proper keyword
        if (pictogram.keyword.startsWith('Pictogram ') && pictogram.id > 0) {
          try {
            final enhanced = await _arasaacService.getPictogramById(pictogram.id);
            if (enhanced != null && enhanced.keyword.isNotEmpty && enhanced.keyword != 'Onbekend') {
              // Use enhanced keyword, keep other properties
              enhancedPictograms.add(pictogram.copyWith(
                keyword: enhanced.keyword,
                category: enhanced.category,
              ));
              continue;
            }
          } catch (e) {
            // Silently fail - use original pictogram
            // Don't log errors when offline (we already checked, but individual requests might fail)
          }
        }
        // Keep original pictogram if enhancement failed or not needed
        enhancedPictograms.add(pictogram);
      }
      
      debugPrint('Enhanced ${enhancedPictograms.length} cached pictograms with keywords');
      return enhancedPictograms;
    } catch (e, stackTrace) {
      debugPrint('Error loading cached pictograms: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Pre-cache pictogram images in the background for offline use
  /// Only caches first 50 pictograms per category for offline mode
  Future<void> _precachePictograms(List<Pictogram> pictograms, String categoryKey) async {
    // Only cache ARASAAC pictograms (not custom ones)
    final arasaacPictograms = pictograms.where((p) => p.id > 0).toList();
    
    // Limit to first 50 pictograms for caching
    const maxCacheCount = 50;
    final pictogramsToCache = arasaacPictograms.take(maxCacheCount).toList();
    
    debugPrint('Pre-caching ${pictogramsToCache.length} pictograms (limited to $maxCacheCount) for category $categoryKey...');
    int cachedCount = 0;
    int errorCount = 0;
    
    // Cache in smaller batches to avoid overwhelming the network
    const batchSize = 10;
    for (int i = 0; i < pictogramsToCache.length; i += batchSize) {
      final batch = pictogramsToCache.skip(i).take(batchSize).toList();
      
      // Process batch in parallel
      await Future.wait(
        batch.map((pictogram) async {
          try {
            // Download and cache (will skip if already cached with correct category)
            final cached = await _arasaacService.downloadAndCachePictogramAtSize(
              pictogram.id,
              size: 500,
              category: categoryKey,
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
      if (i + batchSize < pictogramsToCache.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if ((i + batchSize) % 50 == 0 || i + batchSize >= pictogramsToCache.length) {
        debugPrint('Pre-cached ${i + batchSize}/${pictogramsToCache.length} pictograms... ($cachedCount cached, $errorCount errors)');
      }
    }
    
    debugPrint('Pre-caching complete: $cachedCount cached, $errorCount errors (limited to first $maxCacheCount)');
  }

  /// Cache image to custom directory when displayed (called for each pictogram in grid)
  void _cacheImageToCustomDirectory(int pictogramId, String category) {
    // Always download and cache (don't skip if already cached)
    // This ensures we always have the latest version and update category metadata
    _arasaacService.downloadAndCachePictogram(pictogramId, category: category).then((file) {
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
    // Reset displayed count when switching categories
    if (!_allPictogramsByCategory.containsKey(category)) {
      _displayedCountByCategory.remove(category);
    }
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
      // ARASAAC pictogram - cache it when displayed with category
      _cacheImageToCustomDirectory(pictogram.id, pictogram.category);
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
    
    // Always show if we have loaded the initial batch
    // Even if we have exactly 18, there might be more available from API
    final displayedCount = _displayedCountByCategory[_selectedCategory] ?? 0;
    final currentPictograms = _pictogramsByCategory[_selectedCategory] ?? [];
    
    // Show button if:
    // 1. We have displayed some pictograms (at least initial load)
    // 2. We're not currently loading more
    // 3. We have at least the initial count (might be more available)
    return displayedCount >= _initialLoadCount && 
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
