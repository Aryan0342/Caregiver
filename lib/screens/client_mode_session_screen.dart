import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../providers/language_provider.dart';
import 'pictogram_picker_screen.dart';

/// Client Mode Session Screen - Locked down AAC mode.
///
/// Features:
/// - Full-screen pictogram view
/// - No back button
/// - No navigation gestures
/// - No settings access
/// - No editing features
/// - Hidden exit mechanism (long-press corner or caregiver icon)
class ClientModeSessionScreen extends StatefulWidget {
  final PictogramSet set;

  const ClientModeSessionScreen({
    super.key,
    required this.set,
  });

  @override
  State<ClientModeSessionScreen> createState() =>
      _ClientModeSessionScreenState();
}

class _ClientModeSessionScreenState extends State<ClientModeSessionScreen> {
  int _currentStepIndex = 0;
  DateTime? _lastExitAttempt;
  List<Pictogram>? _modifiedSequence; // Temporary modified sequence (not saved)

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    // Disable back button completely, but allow AppBar back button
    return PopScope(
      canPop: false, // Prevent back button and navigation gestures
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () {
              // Navigate back to pictogram sets page
              Navigator.pop(context);
            },
          ),
          actions: [
            // Modify button in top right
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: Icon(Icons.edit, color: AppTheme.accentOrange, size: 20),
                label: Text(
                  localizations.modify,
                  style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  _modifySequence();
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Main content (without buttons)
              _buildMainContentWithoutButtons(),

              // Hidden exit areas (invisible but tappable) - positioned behind buttons
              _buildHiddenExitAreas(),

              // Buttons on top layer to ensure they're clickable
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentWithoutButtons() {
    final localizations = LanguageProvider.localizationsOf(context);

    // Use modified sequence if available, otherwise use original
    final pictograms = _modifiedSequence ?? widget.set.pictograms;

    if (pictograms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              localizations.noPictogramsInSet,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    final currentPictogram = pictograms[_currentStepIndex];
    final isLastStep = _currentStepIndex == pictograms.length - 1;

    return Column(
      children: [
        // Fullscreen pictogram display
        Expanded(
          child: GestureDetector(
            // Tap anywhere on pictogram to go to next step
            onTap: isLastStep
                ? null
                : () {
                    _nextStep();
                  },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPictogramImage(currentPictogram),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Large label (Displays localized Dutch keyword from model)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Text(
              _getPictogramKeyword(currentPictogram),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Pictograms preview (tiny, under the title) - shows only next pictograms (not current)
        // Only show if there are upcoming pictograms, and only show actual pictograms (up to 3)
        if (!isLastStep)
          Builder(
            builder: (context) {
              // Calculate how many upcoming pictograms there are (max 3)
              final remainingCount =
                  pictograms.length - (_currentStepIndex + 1);
              final previewCount = remainingCount > 3
                  ? 3
                  : (remainingCount > 0 ? remainingCount : 0);

              // Don't show preview bar if there are no upcoming pictograms
              if (previewCount == 0) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  // Label for upcoming pictograms preview
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      LanguageProvider.localizationsOf(context).upcomingPictos,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Preview row with only actual pictograms (no empty boxes)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      height: 60,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            previewCount, // Only show actual pictograms
                            (previewIndex) {
                              // Start from next pictogram (skip current)
                              final actualIndex =
                                  _currentStepIndex + 1 + previewIndex;
                              final pictogram = pictograms[actualIndex];

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildTinyPictogramPreview(
                                  pictogram,
                                  actualIndex + 1,
                                  isCurrent: false,
                                  isPrevious: false,
                                  isNext: true,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        // Add spacer for buttons area
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildActionButtons() {
    final localizations = LanguageProvider.localizationsOf(context);
    final pictograms = _modifiedSequence ?? widget.set.pictograms;
    final isLastStep = _currentStepIndex == pictograms.length - 1;
    final isFirstStep = _currentStepIndex == 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // "Vorige" button (was "Terug")
              Expanded(
                child: GestureDetector(
                  onTap: isFirstStep
                      ? null
                      : () {
                          _previousStep();
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Material(
                    color: isFirstStep
                        ? AppTheme.accentRed.withValues(alpha: 0.5)
                        : AppTheme.accentRed,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 8),
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back,
                              size: 24, color: Colors.white),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              localizations.previous,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // "Volgende" / "Klaar" button
              Expanded(
                child: GestureDetector(
                  onTap: isLastStep
                      ? () {
                          _exitWithPin();
                        }
                      : () {
                          _nextStep();
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Material(
                    color: isLastStep
                        ? AppTheme.accentGreenDark
                        : AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 8),
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLastStep ? Icons.check : Icons.arrow_forward,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isLastStep
                                  ? localizations.done
                                  : localizations.next,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get pictogram keyword - all pictograms are now custom with stored keywords
  String _getPictogramKeyword(Pictogram pictogram) {
    return pictogram.keyword.isNotEmpty ? pictogram.keyword : 'Onbekend';
  }

  /// Build hidden exit areas (invisible but tappable)
  Widget _buildHiddenExitAreas() {
    return Stack(
      children: [
        // Top-left corner (long-press to exit)
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onLongPress: _handleExitAttempt,
            child: Container(
              width: 80,
              height: 80,
              color: Colors.transparent,
            ),
          ),
        ),
        // Top-right corner (long-press to exit)
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onLongPress: _handleExitAttempt,
            child: Container(
              width: 80,
              height: 80,
              color: Colors.transparent,
            ),
          ),
        ),
        // Bottom-left corner (long-press to exit) - exclude button area
        // Buttons are ~120px from bottom, so only capture area above buttons
        Positioned(
          bottom: 120,
          left: 0,
          child: GestureDetector(
            onLongPress: _handleExitAttempt,
            child: Container(
              width: 80,
              height: 80,
              color: Colors.transparent,
            ),
          ),
        ),
        // Bottom-right corner (long-press to exit) - exclude button area
        Positioned(
          bottom: 120,
          right: 0,
          child: GestureDetector(
            onLongPress: _handleExitAttempt,
            child: Container(
              width: 80,
              height: 80,
              color: Colors.transparent,
            ),
          ),
        ),
        // Caregiver icon in center-top (long-press to exit)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onLongPress: _handleExitAttempt,
            child: Container(
              height: 60,
              alignment: Alignment.center,
              color: Colors.transparent,
              child: Icon(
                Icons.person_outline,
                color: Colors.transparent, // Invisible but tappable
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    if (!mounted) return;

    final pictograms = _modifiedSequence ?? widget.set.pictograms;
    if (_currentStepIndex < pictograms.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _modifySequence() async {
    final currentSequence =
        _modifiedSequence ?? List<Pictogram>.from(widget.set.pictograms);

    // Show dialog to modify sequence
    final result = await showDialog<List<Pictogram>>(
      context: context,
      builder: (context) => _ModifySequenceDialog(
        currentSequence: currentSequence,
        currentIndex: _currentStepIndex,
      ),
    );

    if (result != null) {
      setState(() {
        _modifiedSequence = result;
        // Reset to first step after modification
        _currentStepIndex = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Volgorde tijdelijk gewijzigd. Wijzigingen worden niet opgeslagen.'),
            backgroundColor: AppTheme.accentOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Handle exit attempt (long-press on hidden areas)
  void _handleExitAttempt() {
    // Prevent rapid-fire exit attempts
    final now = DateTime.now();
    if (_lastExitAttempt != null &&
        now.difference(_lastExitAttempt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastExitAttempt = now;

    // Require PIN to exit
    _exitWithPin();
  }

  /// Exit client mode (no PIN required since PIN was verified to enter)
  Future<void> _exitWithPin() async {
    final localizations = LanguageProvider.localizationsOf(context);

    // Show completion message and exit (PIN was already verified to enter client mode)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.allStepsCompleted),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      // Navigate back after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }

  Widget _buildPictogramImage(Pictogram pictogram) {
    // All pictograms are now custom with Cloudinary URLs
    if (pictogram.imageUrl.isEmpty) {
      return _buildFallbackIcon(_getIconForKeyword(pictogram.keyword));
    }

    return Image.network(
      pictogram.imageUrl, // Cloudinary URL
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            strokeWidth: 4,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _buildFallbackIcon(_getIconForKeyword(pictogram.keyword)),
    );
  }

  Widget _buildFallbackIcon(IconData icon) {
    return Center(
      child: Icon(
        icon,
        size: 150,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildTinyPictogramPreview(
    Pictogram pictogram,
    int stepNumber, {
    bool isCurrent = false,
    bool isPrevious = false,
    bool isNext = false,
  }) {
    // Determine border color based on state
    Color borderColor;
    if (isCurrent) {
      borderColor = AppTheme.accentGreen; // Green for current
    } else if (isPrevious) {
      borderColor = AppTheme.textSecondary; // Gray for previous (completed)
    } else {
      borderColor =
          AppTheme.primaryBlue.withValues(alpha: 0.3); // Blue for next
    }

    // Determine background opacity based on state
    double backgroundAlpha;
    if (isCurrent) {
      backgroundAlpha = 0.4; // More visible for current
    } else if (isPrevious) {
      backgroundAlpha = 0.15; // Less visible for previous
    } else {
      backgroundAlpha = 0.2; // Normal for next
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueLight.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 2 : 1, // Thicker border for current
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Pictogram image
            Opacity(
              opacity: isPrevious ? 0.6 : 1.0, // Dim previous items
              child: pictogram.imageUrl.isNotEmpty
                  ? Image.network(
                      pictogram.imageUrl, // Cloudinary URL
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getIconForKeyword(pictogram.keyword),
                        size: 20,
                        color: AppTheme.primaryBlue,
                      ),
                    )
                  : Icon(
                      _getIconForKeyword(pictogram.keyword),
                      size: 20,
                      color: AppTheme.primaryBlue,
                    ),
            ),
            // Step number badge
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.accentGreen
                      : isPrevious
                          ? AppTheme.textSecondary
                          : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Checkmark for completed (previous) items
            if (isPrevious)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
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
    if (lowerKeyword.contains('eten') ||
        lowerKeyword.contains('drink') ||
        lowerKeyword.contains('food')) {
      return Icons.restaurant;
    } else if (lowerKeyword.contains('toilet') || lowerKeyword.contains('wc')) {
      return Icons.wc;
    } else if (lowerKeyword.contains('slapen') ||
        lowerKeyword.contains('bed')) {
      return Icons.bed;
    } else if (lowerKeyword.contains('spelen') ||
        lowerKeyword.contains('spel')) {
      return Icons.toys;
    } else if (lowerKeyword.contains('buiten') ||
        lowerKeyword.contains('buiten')) {
      return Icons.park;
    } else {
      return Icons.image_outlined;
    }
  }
}

/// Dialog for modifying the pictogram sequence temporarily
class _ModifySequenceDialog extends StatefulWidget {
  final List<Pictogram> currentSequence;
  final int currentIndex;

  const _ModifySequenceDialog({
    required this.currentSequence,
    required this.currentIndex,
  });

  @override
  State<_ModifySequenceDialog> createState() => _ModifySequenceDialogState();
}

class _ModifySequenceDialogState extends State<_ModifySequenceDialog> {
  late List<Pictogram> _modifiedSequence;

  @override
  void initState() {
    super.initState();
    _modifiedSequence = List<Pictogram>.from(widget.currentSequence);
  }

  void _reorderPictogram(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _modifiedSequence.removeAt(oldIndex);
      _modifiedSequence.insert(newIndex, item);
    });
  }

  Future<void> _addPictograms() async {
    final selected = await Navigator.push<List<Pictogram>>(
      context,
      MaterialPageRoute(
        builder: (context) => PictogramPickerScreen(
          initialSelection: _modifiedSequence,
          maxSelection: 50, // Allow many pictograms to be added
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        // Add only the newly selected pictograms (not already in sequence)
        final existingIds = _modifiedSequence.map((p) => p.id).toSet();
        final newPictograms =
            selected.where((p) => !existingIds.contains(p.id)).toList();
        _modifiedSequence.addAll(newPictograms);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    return AlertDialog(
      title: Text(localizations.modifySequence),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.modifySequenceDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Add pictogram button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addPictograms,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(localizations.addPictograms),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _modifiedSequence.length,
                onReorder: _reorderPictogram,
                itemBuilder: (context, index) {
                  final pictogram = _modifiedSequence[index];
                  return _buildPictogramListItem(pictogram, index);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_modifiedSequence),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
          ),
          child: Text(localizations.save),
        ),
      ],
    );
  }

  Widget _buildPictogramListItem(Pictogram pictogram, int index) {
    return Card(
      key: ValueKey(pictogram.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlueLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
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
                      Icons.image_outlined,
                      size: 24,
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : Icon(
                    Icons.image_outlined,
                    size: 24,
                    color: AppTheme.primaryBlue,
                  ),
          ),
        ),
        title: Text(
          pictogram.keyword,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Stap ${index + 1}'),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }
}
