import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/pictogram_model.dart';
import '../services/custom_pictogram_service.dart';
import '../services/category_service.dart';
import '../services/language_service.dart';
import '../theme.dart';
import '../providers/language_provider.dart';
import 'request_picto_screen.dart';

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
  final CustomPictogramService _pictogramService = CustomPictogramService();
  final CategoryService _categoryService = CategoryService();
  
  final Map<String, List<Pictogram>> _pictogramsByCategory = {};
  final Set<Pictogram> _selectedPictograms = {};
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<Pictogram> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedPictograms.addAll(widget.initialSelection!);
    }
    _loadCategories();
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
      final results = await _pictogramService.searchPictograms(query);
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

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final categories = await _categoryService.getCategoriesWithPictograms();
      
      if (categories.isEmpty) {
        setState(() {
          _categories = [];
          _selectedCategory = null;
          _isLoadingCategories = false;
          _errorMessage = 'Geen categorieën met pictogrammen beschikbaar.';
        });
        return;
      }

      setState(() {
        _categories = categories;
        _selectedCategory = categories.first;
        _isLoadingCategories = false;
      });

      // Load pictograms for the first category
      if (_selectedCategory != null) {
        _loadPictograms(_selectedCategory!);
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _errorMessage = 'Fout bij laden van categorieën. Probeer het opnieuw.';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadPictograms(Category category) async {
    // Check if already loaded
    if (_pictogramsByCategory.containsKey(category.id)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Loading pictograms for category: ${category.id} (${category.name})');
      final pictograms = await _pictogramService.getPictogramsByCategory(category.id);
      debugPrint('Loaded ${pictograms.length} pictograms for category ${category.id}');
      
      setState(() {
        _pictogramsByCategory[category.id] = pictograms;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading pictograms for category ${category.id}: $e');
      setState(() {
        _errorMessage = 'Fout bij laden van pictogrammen. Probeer het opnieuw.';
        _isLoading = false;
      });
    }
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
              backgroundColor: AppTheme.accentOrange,
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

  void _onCategoryChanged(Category category) {
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
    final languageService = LanguageProvider.languageServiceOf(context);
    final languageCode = languageService.currentLanguage == AppLanguage.dutch ? 'nl' : 'en';
    
    // Show search results if searching, otherwise show category pictograms
    final currentPictograms = _isSearching 
        ? _searchResults 
        : (_selectedCategory != null 
            ? (_pictogramsByCategory[_selectedCategory!.id] ?? [])
            : []);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.choosePictograms),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Geen categorieën beschikbaar',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCategories,
                        child: const Text('Opnieuw proberen'),
                      ),
                    ],
                  ),
                )
              : Column(
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
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory?.id == category.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: FilterChip(
                              label: Text(category.getLocalizedName(languageCode)),
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
                                        onPressed: () {
                                          if (_selectedCategory != null) {
                                            _loadPictograms(_selectedCategory!);
                                          }
                                        },
                                        child: const Text('Opnieuw proberen'),
                                      ),
                                    ],
                                  ),
                                )
                              : currentPictograms.isEmpty
                                  ? Center(
                                      child: Text(
                                        _isSearching 
                                            ? 'Geen pictogrammen gevonden'
                                            : 'Geen pictogrammen in deze categorie',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    )
                                  : GridView.builder(
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
                    // Bottom bar with Done and Request picto buttons
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            // Request picto button (moved to left)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RequestPictoScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                                label: Text(
                                  localizations.requestPicto,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedPictograms.isNotEmpty)
                              const SizedBox(width: 12),
                            // Done button (moved to right, only show if items are selected)
                            if (_selectedPictograms.isNotEmpty)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _confirmSelection,
                                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                  label: Text(
                                    '${localizations.done} (${_selectedPictograms.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
                  // Keyword label
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
    if (pictogram.imageUrl.isEmpty) {
      return _buildFallbackIcon(_getIconForKeyword(pictogram.keyword));
    }

    return Image.network(
      pictogram.imageUrl, // Cloudinary URL
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(_getIconForKeyword(pictogram.keyword)),
    );
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
