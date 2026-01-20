import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/pictogram_model.dart';
import '../models/set_model.dart';
import '../services/set_service.dart';
import '../services/arasaac_service.dart';
import '../providers/language_provider.dart';
import '../utils/pin_guard.dart';
import 'pictogram_picker_screen.dart';

class EditSetScreen extends StatefulWidget {
  final PictogramSet set;

  const EditSetScreen({
    super.key,
    required this.set,
  });

  @override
  State<EditSetScreen> createState() => _EditSetScreenState();
}

class _EditSetScreenState extends State<EditSetScreen> {
  final _setService = SetService();
  final _arasaacService = ArasaacService();
  final _nameController = TextEditingController();
  List<Pictogram> _selectedPictograms = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.set.name;
    _selectedPictograms = List.from(widget.set.pictograms);
    _checkPin();
  }

  Future<void> _checkPin() async {
    final verified = await PinGuard.requirePin(
      context,
      title: 'Pictoreeks bewerken',
      subtitle: 'Voer uw pincode in om de pictoreeks te bewerken',
    );

    if (mounted) {
      // If PIN not verified, go back
      if (!verified) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openPictogramPicker() async {
    final selected = await Navigator.push<List<Pictogram>>(
      context,
      MaterialPageRoute(
        builder: (context) => PictogramPickerScreen(
          initialSelection: _selectedPictograms,
          maxSelection: 20,
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedPictograms = selected;
      });
    }
  }

  void _reorderPictogram(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _selectedPictograms.removeAt(oldIndex);
      _selectedPictograms.insert(newIndex, item);
    });
  }

  Future<void> _saveSet() async {
    final localizations = LanguageProvider.localizationsOf(context);
    
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.enterName),
          backgroundColor: AppTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_selectedPictograms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.selectAtLeastOne),
          backgroundColor: AppTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedSet = widget.set.copyWith(
        name: _nameController.text.trim(),
        pictograms: _selectedPictograms,
        updatedAt: DateTime.now(),
      );

      await _setService.updateSet(updatedSet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.setUpdated),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        final isOffline = errorMessage.toLowerCase().contains('offline');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline 
                ? 'Offline: Wijzigingen worden opgeslagen zodra u weer online bent'
                : 'Fout bij opslaan: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}',
            ),
            backgroundColor: isOffline ? AppTheme.accentOrange : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        
        // If offline, still allow navigation back (data will sync when online)
        if (isOffline) {
          Navigator.pop(context, true);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.editPictogramSet),
        backgroundColor: AppTheme.primaryBlueLight,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Name input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: localizations.name,
                  hintText: localizations.giveAName,
                  prefixIcon: const Icon(Icons.label_outline, size: 28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Selected pictograms count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primaryBlueLight.withOpacity(0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedPictograms.length} ${localizations.pictogramsSelected}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TextButton.icon(
                      onPressed: _openPictogramPicker,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(localizations.addPictograms),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pictogram list (reorderable)
            Expanded(
              child: _selectedPictograms.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 80,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                          Text(
                            localizations.noPictogramsSelected,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openPictogramPicker,
                            icon: const Icon(Icons.add),
                            label: Text(localizations.choosePictograms),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      scrollDirection: Axis.vertical,
                      itemCount: _selectedPictograms.length,
                      onReorder: _reorderPictogram,
                      itemBuilder: (context, index) {
                        final pictogram = _selectedPictograms[index];
                        return _buildPictogramCard(pictogram, index);
                      },
                    ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : Text(
                            localizations.save,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictogramCard(Pictogram pictogram, int index) {
    return Card(
      key: ValueKey(pictogram.id),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 120,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Drag handle
            Icon(
              Icons.drag_handle,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            // Pictogram image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
              child: Image.network(
                  // For custom pictograms, use the imageUrl from the model
                  // For ARASAAC pictograms, use thumbnail URL (500px) for small cards
                  pictogram.imageUrl.isNotEmpty && pictogram.id < 0
                      ? pictogram.imageUrl // Custom pictogram
                      : _arasaacService.getThumbnailUrl(pictogram.id), // ARASAAC pictogram
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Try preview URL (1000px) as fallback
                    final previewUrl = _arasaacService.getPreviewUrl(pictogram.id);
                    if (previewUrl != _arasaacService.getThumbnailUrl(pictogram.id)) {
                      return Image.network(
                        previewUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          _getIconForKeyword(pictogram.keyword),
                          size: 32,
                          color: AppTheme.primaryBlue,
                        ),
                      );
                    }
                    return Icon(
                      _getIconForKeyword(pictogram.keyword),
                      size: 32,
                      color: AppTheme.primaryBlue,
                    );
                  },
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Keyword and index
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Keyword - displays localized Dutch keyword from model
                  Text(
                    pictogram.keyword,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Index number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stap ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    if (lowerKeyword.contains('wakker') || lowerKeyword.contains('opstaan')) {
      return Icons.access_time;
    } else if (lowerKeyword.contains('aankleden')) {
      return Icons.checkroom;
    } else if (lowerKeyword.contains('ontbijt') || lowerKeyword.contains('eten')) {
      return Icons.restaurant;
    } else if (lowerKeyword.contains('tanden') || lowerKeyword.contains('poets')) {
      return Icons.cleaning_services;
    }
    return Icons.image_outlined;
  }
}
