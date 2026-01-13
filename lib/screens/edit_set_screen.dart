import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/pictogram_model.dart';
import '../models/set_model.dart';
import '../services/set_service.dart';
import '../services/arasaac_service.dart';
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
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Voer een naam in'),
          backgroundColor: Colors.orange,
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
          content: const Text('Selecteer minimaal één pictogram'),
          backgroundColor: Colors.orange,
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
            content: const Text('Pictoreeks bijgewerkt!'),
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
            backgroundColor: isOffline ? Colors.orange : Colors.red,
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Pictoreeks bewerken'),
        backgroundColor: AppTheme.primaryBlueLight,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Name input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Naam',
                  hintText: 'Geef een naam…',
                  prefixIcon: const Icon(Icons.label_outline, size: 28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Selected pictograms count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.primaryBlueLight.withOpacity(0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedPictograms.length} pictogrammen geselecteerd',
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
                      label: const Text('Toevoegen'),
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
                            'Geen pictogrammen geselecteerd',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openPictogramPicker,
                            icon: const Icon(Icons.add),
                            label: const Text('Pictogrammen kiezen'),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      scrollDirection: Axis.horizontal,
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
              padding: const EdgeInsets.all(16),
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
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSet,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 64),
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
                            'Opslaan',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
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
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 100,
          maxWidth: 120,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Drag handle
            Icon(
              Icons.drag_handle,
              color: AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(height: 6),
            // Pictogram image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CachedNetworkImage(
                  imageUrl: _arasaacService.getStaticImageUrl(pictogram.id),
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    _getIconForKeyword(pictogram.keyword),
                    size: 32,
                    color: AppTheme.primaryBlue,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Keyword
            Flexible(
              child: Text(
                pictogram.keyword,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Index number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
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
