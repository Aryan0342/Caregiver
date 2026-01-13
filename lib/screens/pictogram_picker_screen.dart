import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pictogram_model.dart';
import '../services/arasaac_service.dart';
import '../theme.dart';

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
  final Set<Pictogram> _selectedPictograms = {};
  PictogramCategory _selectedCategory = PictogramCategory.dagelijks;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedPictograms.addAll(widget.initialSelection!);
    }
    _loadPictograms(_selectedCategory);
  }

  Future<void> _loadPictograms(PictogramCategory category) async {
    if (_pictogramsByCategory.containsKey(category)) {
      // Already loaded
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pictograms = await _arasaacService.searchPictograms(
        category: category,
        limit: 50,
      );

      setState(() {
        _pictogramsByCategory[category] = pictograms;
        _isLoading = false;
      });
    } catch (e) {
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
    });
    _loadPictograms(category);
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedPictograms.toList());
  }

  @override
  Widget build(BuildContext context) {
    final currentPictograms = _pictogramsByCategory[_selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Pictogrammen kiezen'),
        backgroundColor: AppTheme.primaryBlueLight,
        actions: [
          if (_selectedPictograms.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Klaar (${_selectedPictograms.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
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
                    label: Text(category.displayName),
                    selected: isSelected,
                    onSelected: (_) => _onCategoryChanged(category),
                    selectedColor: AppTheme.primaryBlue,
                    checkmarkColor: Colors.white,
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
                    child: CachedNetworkImage(
                      imageUrl: _arasaacService.getImageUrl(pictogram.id),
                      placeholder: (context, url) => Container(
                        color: AppTheme.primaryBlueLight.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.primaryBlueLight.withOpacity(0.1),
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppTheme.textSecondary,
                          size: 40,
                        ),
                      ),
                      fit: BoxFit.contain,
                    ),
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
}
