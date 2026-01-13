import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/set_model.dart';
import '../services/arasaac_service.dart';

class ClientSessionScreen extends StatefulWidget {
  final PictogramSet set;

  const ClientSessionScreen({
    super.key,
    required this.set,
  });

  @override
  State<ClientSessionScreen> createState() => _ClientSessionScreenState();
}

class _ClientSessionScreenState extends State<ClientSessionScreen> {
  final ArasaacService _arasaacService = ArasaacService();
  int _currentStepIndex = 0;

  void _nextStep() {
    if (_currentStepIndex < widget.set.pictograms.length - 1) {
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

  void _markAsDone() {
    // Move to next step after marking as done
    _nextStep();
    
    // Show completion message if at the end
    if (_currentStepIndex >= widget.set.pictograms.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alle stappen voltooid!'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPictogram = widget.set.pictograms[_currentStepIndex];
    final isFirstStep = _currentStepIndex == 0;
    final isLastStep = _currentStepIndex == widget.set.pictograms.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.set.name),
        backgroundColor: AppTheme.primaryBlueLight,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryBlueLight.withOpacity(0.3),
              child: Row(
                children: [
                  Text(
                    'Stap ${_currentStepIndex + 1} van ${widget.set.pictograms.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  // Progress dots
                  Row(
                    children: List.generate(
                      widget.set.pictograms.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= _currentStepIndex
                              ? AppTheme.primaryBlue
                              : AppTheme.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main pictogram display
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large pictogram image
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: _arasaacService.getImageUrl(currentPictogram.id),
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Pictogram label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          currentPictogram.keyword,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
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
                child: Row(
                  children: [
                    // Previous button
                    if (!isFirstStep)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _previousStep,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Vorige'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                        ),
                      ),
                    if (!isFirstStep) const SizedBox(width: 12),

                    // Done button
                    Expanded(
                      flex: isFirstStep ? 1 : 1,
                      child: ElevatedButton.icon(
                        onPressed: _markAsDone,
                        icon: const Icon(Icons.check),
                        label: const Text('Klaar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      ),
                    ),

                    // Next button
                    if (!isLastStep) const SizedBox(width: 12),
                    if (!isLastStep)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _nextStep,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Volgende stap'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
