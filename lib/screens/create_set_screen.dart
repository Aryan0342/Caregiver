import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../models/pictogram_model.dart';
import '../models/set_model.dart';
import '../services/set_service.dart';
import '../services/arasaac_service.dart';
import 'pictogram_picker_screen.dart';
import 'client_mode_session_screen.dart';
import '../providers/language_provider.dart';

class CreateSetScreen extends StatefulWidget {
  const CreateSetScreen({super.key});

  @override
  State<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends State<CreateSetScreen> {
  final _setService = SetService();
  final _arasaacService = ArasaacService();
  final _nameController = TextEditingController();
  List<Pictogram> _selectedPictograms = [];
  int _currentStep = 1; // 1 = Name input, 2 = Pictogram selection/reorder
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (_nameController.text.trim().isEmpty) {
      final localizations = LanguageProvider.localizationsOf(context);
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

    setState(() {
      _currentStep = 2;
    });
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

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.notLoggedIn),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newSet = PictogramSet(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        userId: userId,
        pictograms: _selectedPictograms,
        createdAt: DateTime.now(),
      );

      await _setService.createSet(newSet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.setSaved),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        final isOffline = errorMessage.toLowerCase().contains('offline') ||
                         errorMessage.toLowerCase().contains('timeout');
        
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
        
        // If offline or timeout, still allow navigation back (data will sync when online)
        if (isOffline) {
          // Firestore will queue the write when online
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

  void _startWithClient() {
    final localizations = LanguageProvider.localizationsOf(context);
    
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

    // Create a temporary PictogramSet (not saved) and navigate to client mode
    final tempSet = PictogramSet(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
      name: _nameController.text.trim().isEmpty 
          ? 'Tijdelijke pictoreeks' 
          : _nameController.text.trim(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'temp',
      pictograms: _selectedPictograms,
      createdAt: DateTime.now(),
    );

    // Navigate to client mode session screen (doesn't save the set)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClientModeSessionScreen(set: tempSet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final localizations = LanguageProvider.localizationsOf(context);
            return Text(_currentStep == 1 ? localizations.newPictogramSet : localizations.selectPictograms);
          },
        ),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 2) {
              // Go back to step 1
              setState(() {
                _currentStep = 1;
              });
            } else {
              // Go back to previous screen (home)
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _currentStep == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon - circular add button with blue background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Input field
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: localizations.name,
                hintText: localizations.giveAName,
                prefixIcon: const Icon(Icons.label_outline, size: 28),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _goToStep2(),
            ),
            const SizedBox(height: 32),

            // Begin button
            ElevatedButton(
              onPressed: _goToStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 20),
                minimumSize: const Size(double.infinity, 64),
              ),
              child: Text(
                localizations.begin,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return SafeArea(
      child: Column(
        children: [
          // Selected pictograms count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
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
                ? SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 300,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 80,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                localizations.noPictogramsSelected,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                textAlign: TextAlign.center,
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

          // Two action buttons: Save set and Start with client
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start with client button (darker beige/brown) - moved to top
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _startWithClient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkGreyBrown,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        minimumSize: const Size(double.infinity, 64),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            localizations.startWithClient,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Save set button (lighter beige) - moved to bottom
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warmTan,
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
                              localizations.saveSet,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
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
