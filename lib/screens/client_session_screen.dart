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

  void _markAsDone() {
    // If not on last step, move to next step
    if (_currentStepIndex < widget.set.pictograms.length - 1) {
      _nextStep();
    } else {
      // If on last step, show completion message and go back
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
      // Optionally navigate back after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.set.pictograms.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Geen pictogrammen in deze reeks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Terug'),
              ),
            ],
          ),
        ),
      );
    }

    final currentPictogram = widget.set.pictograms[_currentStepIndex];
    final isLastStep = _currentStepIndex == widget.set.pictograms.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fullscreen pictogram display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Fullscreen pictogram image
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CachedNetworkImage(
                              imageUrl: _arasaacService.getStaticImageUrl(currentPictogram.id),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlue,
                                  ),
                                  strokeWidth: 4,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 120,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Large label in Dutch
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentPictogram.keyword,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            // Action buttons - only "Klaar" and "Volgende stap"
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // "Klaar" button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _markAsDone,
                        icon: const Icon(Icons.check, size: 28),
                        label: const Text(
                          'Klaar',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: AppTheme.accentGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // "Volgende stap" button (only show if not last step)
                    if (!isLastStep)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _nextStep,
                          icon: const Icon(Icons.arrow_forward, size: 28),
                          label: const Text(
                            'Volgende stap',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
