import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../models/pictogram_model.dart';
import '../models/set_model.dart';
import '../services/set_service.dart';
import 'pictogram_picker_screen.dart';
import 'client_mode_session_screen.dart';
import 'my_sets_screen.dart';
import '../providers/language_provider.dart';

class CreateSetScreen extends StatefulWidget {
  final List<Pictogram>? initialPictograms;

  const CreateSetScreen({
    super.key,
    this.initialPictograms,
  });

  @override
  State<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends State<CreateSetScreen> {
  final _setService = SetService();
  final _nameController = TextEditingController();
  late List<Pictogram> _selectedPictograms = [];
  late int _currentStep;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // If initial pictograms are provided, start from step 2
    // Otherwise start from step 1 (naming)
    if (widget.initialPictograms != null &&
        widget.initialPictograms!.isNotEmpty) {
      _selectedPictograms = List.from(widget.initialPictograms!);
      _currentStep = 2; // Skip the naming step
    } else {
      _selectedPictograms = [];
      _currentStep = 1; // Show naming step
    }
  }

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

    // If we have pre-selected pictograms, save directly
    // Otherwise go to Step 2 (pictogram selection)
    if (_selectedPictograms.isNotEmpty) {
      _saveSet();
    } else {
      setState(() {
        _currentStep = 2;
      });
    }
  }

  void _goToNamingStep() {
    setState(() {
      _currentStep = 1;
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

  void _removePictogram(int index) {
    setState(() {
      _selectedPictograms.removeAt(index);
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

    // If name is empty, ask user for a name
    if (_nameController.text.trim().isEmpty) {
      if (!mounted) return;

      final name = await _showNameDialog(context);
      if (name == null || name.isEmpty) {
        return; // User cancelled
      }
      _nameController.text = name;
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MySetsScreen(),
          ),
        );
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
                  : 'Fout bij opslaan: ${errorMessage.length > 100 ? '${errorMessage.substring(0, 100)}...' : errorMessage}',
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MySetsScreen(),
            ),
          );
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

  Future<String?> _showNameDialog(BuildContext context) async {
    final localizations = LanguageProvider.localizationsOf(context);
    final nameController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations.name),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: localizations.giveAName,
            prefixIcon: const Icon(Icons.label_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.enterName),
                    backgroundColor: AppTheme.accentOrange,
                  ),
                );
                return;
              }
              Navigator.pop(context, name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: Text(
              localizations.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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

    // Create and save as auto-saved set before starting
    _saveAutoAndStart();
  }

  Future<void> _saveAutoAndStart() async {
    final setService = SetService();

    // Create a temporary PictogramSet as auto-saved
    final tempSet = PictogramSet(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      name: '', // Empty name for auto-saved sets
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'temp',
      pictograms: _selectedPictograms,
      createdAt: DateTime.now(),
      isAutoSaved: true, // Mark as auto-saved
    );

    try {
      // Save to Firestore
      final savedId = await setService.createSet(tempSet);

      if (savedId != null && mounted) {
        // Update the set with the actual saved ID
        final savedSet = tempSet.copyWith(id: savedId);

        // Navigate to client mode session screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientModeSessionScreen(set: savedSet),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-saving set: $e');
      // Fallback: navigate without saving
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientModeSessionScreen(set: tempSet),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final localizations = LanguageProvider.localizationsOf(context);
            return Text(_currentStep == 1
                ? localizations.newPictogramSet
                : localizations.selectPictograms);
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon - save icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.save,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Helper text
              Text(
                localizations.namingGuide,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

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

              // Save button
              ElevatedButton(
                onPressed: _goToStep2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  minimumSize: const Size(double.infinity, 64),
                ),
                child: Text(
                  localizations.save,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                localizations.noPictogramsSelected,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
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
                          const Icon(Icons.play_arrow,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            localizations.startWithClient,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
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
                      onPressed: _isSaving ? null : _goToNamingStep,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              localizations.saveSet,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
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
    return Dismissible(
      key: ValueKey('pictogram-${pictogram.id}-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        _removePictogram(index);
      },
      child: Card(
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
                  child: pictogram.imageUrl.isNotEmpty
                      ? Image.network(
                          pictogram.imageUrl, // Cloudinary URL
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlue),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _getIconForKeyword(pictogram.keyword),
                            size: 32,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : Icon(
                          _getIconForKeyword(pictogram.keyword),
                          size: 32,
                          color: AppTheme.primaryBlue,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
              const SizedBox(width: 8),
              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 24,
                ),
                onPressed: () => _removePictogram(index),
                tooltip: 'Remove',
                splashRadius: 24,
              ),
            ],
          ),
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
    } else if (lowerKeyword.contains('ontbijt') ||
        lowerKeyword.contains('eten')) {
      return Icons.restaurant;
    } else if (lowerKeyword.contains('tanden') ||
        lowerKeyword.contains('poets')) {
      return Icons.cleaning_services;
    }
    return Icons.image_outlined;
  }
}
