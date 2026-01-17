import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../services/arasaac_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';

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
  final Map<int, String> _keywordCache = {}; // Cache for fetched keywords

  void _nextStep() {
    if (_currentStepIndex < widget.set.pictograms.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  /// Get pictogram keyword, fetching from ARASAAC if needed
  Future<String> _getPictogramKeyword(Pictogram pictogram) async {
    // If keyword is already valid, return it
    if (pictogram.keyword.isNotEmpty && pictogram.keyword != 'Onbekend') {
      return pictogram.keyword;
    }
    
    // Check cache first
    if (_keywordCache.containsKey(pictogram.id)) {
      return _keywordCache[pictogram.id]!;
    }
    
    // Try to fetch keyword from ARASAAC by ID
    try {
      final fetchedPictogram = await _arasaacService.getPictogramById(pictogram.id);
      if (fetchedPictogram != null) {
        final keyword = fetchedPictogram.keyword;
        if (keyword.isNotEmpty && keyword != 'Onbekend') {
          _keywordCache[pictogram.id] = keyword;
          return keyword;
        }
      }
    } catch (e) {
      // Silently fail - use stored keyword
      if (kDebugMode) {
        debugPrint('Error fetching keyword for pictogram ${pictogram.id}: $e');
      }
    }
    
    // Last resort: return stored keyword (even if it's "Onbekend")
    // Don't show "Pictogram {id}" - just show the stored keyword
    return pictogram.keyword;
  }

  void _markAsDone() {
    // Always navigate back to My Pictogram Sets screen when Done is clicked
    final localizations = LanguageProvider.localizationsOf(context);
    
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
      // Navigate back to My Sets screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.mySets,
        (route) => route.isFirst,
      );
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
                        child: FutureBuilder<String>(
                          future: _getPictogramKeyword(currentPictogram),
                          builder: (context, snapshot) {
                            // Always show the stored keyword first, even if it's "Onbekend"
                            // Only show "..." if we're actively fetching AND have no stored keyword
                            final storedKeyword = currentPictogram.keyword;
                            final isFetching = snapshot.connectionState == ConnectionState.waiting;
                            
                            // If we have a stored keyword (even if "Onbekend"), show it
                            if (storedKeyword.isNotEmpty) {
                              // If fetching and we have a stored keyword, show it (don't show "...")
                              if (isFetching) {
                                return Text(
                                  storedKeyword,
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36,
                                      ),
                                  textAlign: TextAlign.center,
                                );
                              }
                              
                              // Use fetched keyword if available, otherwise use stored
                              final keyword = snapshot.data ?? storedKeyword;
                              return Text(
                                keyword,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 36,
                                    ),
                                textAlign: TextAlign.center,
                              );
                            }
                            
                            // Only show "..." if we have no stored keyword AND are fetching
                            if (isFetching) {
                              return Text(
                                '...',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 36,
                                    ),
                                textAlign: TextAlign.center,
                              );
                            }
                            
                            // Final fallback: use fetched keyword or empty string
                            final keyword = snapshot.data ?? '';
                            return Text(
                              keyword.isEmpty ? '' : keyword,
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 36,
                                  ),
                              textAlign: TextAlign.center,
                            );
                          },
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
    // For custom pictograms, use the imageUrl from the model (Firebase Storage URL)
    // For ARASAAC pictograms, check cache first for offline support
    if (pictogram.imageUrl.isNotEmpty && pictogram.id < 0) {
      // Custom pictogram - use stored Firebase Storage URL directly
      return CachedNetworkImage(
        imageUrl: pictogram.imageUrl,
        fit: BoxFit.contain,
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
        errorWidget: (context, url, error) => _buildFallbackIcon(pictogram),
      );
    }
    
    // ARASAAC pictogram - check cache first for offline support
    return FutureBuilder<File?>(
      future: _arasaacService.getCachedImage(pictogram.id),
      builder: (context, snapshot) {
        // If cached image exists, use it
        if (snapshot.hasData && snapshot.data != null) {
          final cachedFile = snapshot.data!;
          return Image.file(
            cachedFile,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // If cached file fails, try network
              return _buildNetworkImageWithFallbacks(pictogram);
            },
          );
        }
        
        // Not cached or still checking - try network with fallbacks
        return _buildNetworkImageWithFallbacks(pictogram);
      },
    );
  }

  Widget _buildNetworkImageWithFallbacks(Pictogram pictogram) {
    // Try network with multiple size fallbacks
    final imageUrl = _arasaacService.getBestQualityImageUrl(pictogram.id);
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
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
