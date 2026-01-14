import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../services/arasaac_service.dart';
import '../providers/language_provider.dart';

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
      final localizations = LanguageProvider.localizationsOf(context);
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
    final localizations = LanguageProvider.localizationsOf(context);
    
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
                localizations.noPictogramsInSet,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.back),
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
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: _buildPictogramImage(currentPictogram),
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
                          // Displays localized Dutch keyword from model
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                        label: Text(
                          localizations.done,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                          label: Text(
                            localizations.nextStep,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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

  Widget _buildPictogramImage(Pictogram pictogram) {
    // Use best quality image for fullscreen display (5000px)
    final imageUrl = _arasaacService.getBestQualityImageUrl(pictogram.id);
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      // Optimize cache for fullscreen images (5000px)
      maxWidthDiskCache: 5000,
      maxHeightDiskCache: 5000,
      memCacheWidth: 5000,
      memCacheHeight: 5000,
      httpHeaders: const {
        'Accept': 'image/png,image/*;q=0.8',
        'User-Agent': 'Flutter-App',
      },
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.primaryBlue,
          ),
          strokeWidth: 4,
        ),
      ),
      errorWidget: (context, url, error) {
        // Try smaller size as fallback (2500px)
        final fallbackUrl = _arasaacService.getStaticImageUrlWithSize(pictogram.id, size: 2500);
        if (fallbackUrl != imageUrl) {
          return CachedNetworkImage(
            imageUrl: fallbackUrl,
            fit: BoxFit.contain,
            maxWidthDiskCache: 2500,
            maxHeightDiskCache: 2500,
            memCacheWidth: 2500,
            memCacheHeight: 2500,
            httpHeaders: const {
              'Accept': 'image/png,image/*;q=0.8',
              'User-Agent': 'Flutter-App',
            },
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue,
                ),
                strokeWidth: 4,
              ),
            ),
            errorWidget: (context, url, error) {
              // Try even smaller size (1500px)
              final smallerUrl = _arasaacService.getStaticImageUrlWithSize(pictogram.id, size: 1500);
              if (smallerUrl != fallbackUrl) {
                return CachedNetworkImage(
                  imageUrl: smallerUrl,
                  fit: BoxFit.contain,
                  maxWidthDiskCache: 1500,
                  maxHeightDiskCache: 1500,
                  memCacheWidth: 1500,
                  memCacheHeight: 1500,
                  httpHeaders: const {
                    'Accept': 'image/png,image/*;q=0.8',
                    'User-Agent': 'Flutter-App',
                  },
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildFallbackIcon(pictogram),
                );
              }
              return _buildFallbackIcon(pictogram);
            },
          );
        }
        return _buildFallbackIcon(pictogram);
      },
    );
  }

  Widget _buildFallbackIcon(Pictogram pictogram) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForKeyword(pictogram.keyword),
            size: 120,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            pictogram.keyword,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
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
    } else if (lowerKeyword.contains('school')) {
      return Icons.school;
    } else if (lowerKeyword.contains('wassen') || lowerKeyword.contains('douche')) {
      return Icons.shower;
    } else if (lowerKeyword.contains('handen')) {
      return Icons.wash;
    } else if (lowerKeyword.contains('medicijn')) {
      return Icons.medication;
    } else if (lowerKeyword.contains('blij') || lowerKeyword.contains('gelukkig')) {
      return Icons.sentiment_very_satisfied;
    } else if (lowerKeyword.contains('verdrietig') || lowerKeyword.contains('droevig')) {
      return Icons.sentiment_very_dissatisfied;
    } else if (lowerKeyword.contains('boos') || lowerKeyword.contains('woedend')) {
      return Icons.sentiment_dissatisfied;
    } else if (lowerKeyword.contains('bang') || lowerKeyword.contains('angst')) {
      return Icons.sentiment_neutral;
    } else if (lowerKeyword.contains('vermoeid') || lowerKeyword.contains('moe')) {
      return Icons.bedtime;
    }
    return Icons.image_outlined;
  }
}
