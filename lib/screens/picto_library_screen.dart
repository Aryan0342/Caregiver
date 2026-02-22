import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/pictogram_model.dart';
import '../services/custom_pictogram_service.dart';
import '../services/category_service.dart';
import '../providers/language_provider.dart';

class PictoLibraryScreen extends StatefulWidget {
  const PictoLibraryScreen({super.key});

  @override
  State<PictoLibraryScreen> createState() => _PictoLibraryScreenState();
}

class _PictoLibraryScreenState extends State<PictoLibraryScreen> {
  final CustomPictogramService _pictogramService = CustomPictogramService();
  final CategoryService _categoryService = CategoryService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Pictogram> _allPictograms = [];
  List<Pictogram> _filteredPictograms = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedLetter;
  String? _currentScrollLetter;
  bool _showScrollIndicator = false;
  Timer? _scrollIndicatorTimer;

  // Map to store the index position of each letter
  final Map<String, int> _letterIndexMap = {};
  final List<String> _alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllPictograms();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollIndicatorTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _filteredPictograms.isEmpty) return;

    // Calculate which letter is appearing from the bottom of the viewport
    final screenWidth = MediaQuery.of(context).size.width;
    const leftPadding = 16.0;
    const rightPadding = 40.0;
    const crossAxisSpacing = 16.0;
    const mainAxisSpacing = 16.0;
    const crossAxisCount = 3;
    const childAspectRatio = 0.9;

    final availableWidth =
        screenWidth - leftPadding - rightPadding - crossAxisSpacing;
    final itemWidth = availableWidth / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Calculate which pictogram is at the bottom of the viewport
    final bottomOffset = scrollOffset + viewportHeight;
    final bottomRowIndex =
        (bottomOffset / (itemHeight + mainAxisSpacing)).floor();
    final pictogramIndex = (bottomRowIndex * crossAxisCount)
        .clamp(0, _filteredPictograms.length - 1);

    if (pictogramIndex < _filteredPictograms.length) {
      final firstChar = _filteredPictograms[pictogramIndex].keyword.isNotEmpty
          ? _filteredPictograms[pictogramIndex].keyword[0].toUpperCase()
          : '#';
      final letter = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';

      if (_currentScrollLetter != letter) {
        setState(() {
          _currentScrollLetter = letter;
          _showScrollIndicator = true;
        });

        // Cancel existing timer and create new one
        _scrollIndicatorTimer?.cancel();
        _scrollIndicatorTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _showScrollIndicator = false;
            });
          }
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPictograms = List.from(_allPictograms);
      } else {
        _filteredPictograms = _allPictograms
            .where((p) => p.keyword.toLowerCase().contains(query))
            .toList();
      }
      _buildLetterIndexMap();
    });
  }

  Future<void> _loadAllPictograms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load pictograms from all categories
      final categories = await _categoryService.getCategoriesWithPictograms();
      final List<Pictogram> allPictos = [];

      for (final category in categories) {
        try {
          final pictos =
              await _pictogramService.getPictogramsByCategory(category.id);
          allPictos.addAll(pictos);
        } catch (e) {
          debugPrint('Error loading category ${category.id}: $e');
        }
      }

      // Remove duplicates based on ID and sort alphabetically
      final uniquePictos = <int, Pictogram>{};
      for (final picto in allPictos) {
        uniquePictos[picto.id] = picto;
      }

      _allPictograms = uniquePictos.values.toList()
        ..sort((a, b) =>
            a.keyword.toLowerCase().compareTo(b.keyword.toLowerCase()));

      _filteredPictograms = List.from(_allPictograms);
      _buildLetterIndexMap();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load pictograms: $e';
      });
    }
  }

  void _buildLetterIndexMap() {
    _letterIndexMap.clear();
    for (int i = 0; i < _filteredPictograms.length; i++) {
      final firstChar = _filteredPictograms[i].keyword.isNotEmpty
          ? _filteredPictograms[i].keyword[0].toUpperCase()
          : '#';

      final letter = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';

      if (!_letterIndexMap.containsKey(letter)) {
        _letterIndexMap[letter] = i;
      }
    }
  }

  void _scrollToLetter(String letter) {
    final index = _letterIndexMap[letter];
    if (index != null && _scrollController.hasClients) {
      setState(() {
        _selectedLetter = letter;
      });

      // Calculate accurate position based on GridView configuration
      final screenWidth = MediaQuery.of(context).size.width;
      const leftPadding = 16.0;
      const rightPadding = 40.0;
      const crossAxisSpacing = 16.0;
      const mainAxisSpacing = 16.0;
      const crossAxisCount = 3;
      const childAspectRatio = 0.9;

      // Calculate item dimensions
      final availableWidth =
          screenWidth - leftPadding - rightPadding - crossAxisSpacing;
      final itemWidth = availableWidth / crossAxisCount;
      final itemHeight = itemWidth / childAspectRatio;

      // Calculate row number (since we have 2 columns)
      final rowIndex = index ~/ crossAxisCount;

      // Calculate scroll position
      final position = rowIndex * (itemHeight + mainAxisSpacing);

      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Reset selected letter after animation
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _selectedLetter = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localizations.pictoLibrary,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Zoeken...',
                    prefixIcon:
                        Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),

          // Letter index sidebar
          _buildLetterIndex(),

          // Scroll indicator tooltip
          if (_showScrollIndicator && _currentScrollLetter != null)
            _buildScrollIndicator(),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return Positioned(
      right: 50,
      top: MediaQuery.of(context).size.height / 2 - 40,
      child: AnimatedOpacity(
        opacity: _showScrollIndicator ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _currentScrollLetter!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllPictograms,
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      );
    }

    if (_filteredPictograms.isEmpty) {
      return Center(
        child: Text(
          'Geen pictogrammen gevonden',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 16, right: 40, bottom: 16, top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredPictograms.length,
      itemBuilder: (context, index) {
        final pictogram = _filteredPictograms[index];
        return _buildPictogramCard(pictogram);
      },
    );
  }

  Widget _buildPictogramCard(Pictogram pictogram) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed size for image to keep it consistent
            SizedBox(
              height: 64,
              width: 64,
              child: Image.network(
                pictogram.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, size: 40);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryBlue,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                pictogram.keyword,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterIndex() {
    return Positioned(
      right: 0,
      top: 80,
      bottom: 0,
      child: Container(
        width: 24,
        color: Colors.transparent,
        child: ListView.builder(
          itemCount: _alphabet.length,
          itemBuilder: (context, index) {
            final letter = _alphabet[index];
            final hasContent = _letterIndexMap.containsKey(letter);
            final isSelected = _selectedLetter == letter;

            return GestureDetector(
              onTap: hasContent ? () => _scrollToLetter(letter) : null,
              child: Container(
                height: 20,
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: isSelected ? 14 : 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: hasContent
                        ? (isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textPrimary)
                        : AppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
