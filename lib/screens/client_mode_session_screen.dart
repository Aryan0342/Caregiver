import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../services/arasaac_service.dart';
import '../providers/language_provider.dart';

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
  State<ClientModeSessionScreen> createState() => _ClientModeSessionScreenState();
}

class _ClientModeSessionScreenState extends State<ClientModeSessionScreen> {
  final ArasaacService _arasaacService = ArasaacService();
  int _currentStepIndex = 0;
  DateTime? _lastExitAttempt;
  final Map<int, String> _keywordCache = {}; // Cache for fetched keywords

  @override
  Widget build(BuildContext context) {
    // Disable back button completely
    return PopScope(
      canPop: false, // Prevent back button and navigation gestures
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              _buildMainContent(),

              // Hidden exit areas (invisible but tappable)
              _buildHiddenExitAreas(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final localizations = LanguageProvider.localizationsOf(context);
    
    if (widget.set.pictograms.isEmpty) {
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

    final currentPictogram = widget.set.pictograms[_currentStepIndex];
    final isLastStep = _currentStepIndex == widget.set.pictograms.length - 1;

    return Column(
      children: [
        // Fullscreen pictogram display
        Expanded(
          child: GestureDetector(
            // Tap anywhere on pictogram to mark as done
            onTap: _markAsDone,
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
    );
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
        // Bottom-left corner (long-press to exit)
        Positioned(
          bottom: 0,
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
        // Bottom-right corner (long-press to exit)
        Positioned(
          bottom: 0,
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
      // If on last step, loop back to first step (no exit without PIN)
      setState(() {
        _currentStepIndex = 0;
      });
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
    // For custom pictograms, use the imageUrl from the model (Firebase Storage URL)
    // For ARASAAC pictograms, check cache first, then try network
    if (pictogram.imageUrl.isNotEmpty && pictogram.id < 0) {
      // Custom pictogram - use stored Firebase Storage URL directly
      return CachedNetworkImage(
        imageUrl: pictogram.imageUrl,
        fit: BoxFit.contain,
        maxWidthDiskCache: 5000,
        maxHeightDiskCache: 5000,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            strokeWidth: 4,
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackIcon(_getIconForKeyword(pictogram.keyword)),
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
              // If cached file fails, try network with fallback sizes
              final fallbackIcon = _getIconForKeyword(pictogram.keyword);
              final imageSizes = [5000, 2500, 1500];
              return _buildImageWithFallbackSizes(pictogram.id, imageSizes, 0, fallbackIcon);
            },
          );
        }
        
        // Not cached or still checking - try network with fallback sizes
        final fallbackIcon = _getIconForKeyword(pictogram.keyword);
        final imageSizes = [5000, 2500, 1500];
        return _buildImageWithFallbackSizes(pictogram.id, imageSizes, 0, fallbackIcon);
      },
    );
  }

  // Helper for image loading with fallbacks
  Widget _buildImageWithFallbackSizes(
    int pictogramId,
    List<int> sizes,
    int currentIndex,
    IconData fallbackIcon,
  ) {
    if (currentIndex >= sizes.length) {
      // All sizes failed, show fallback icon
      return _buildFallbackIcon(fallbackIcon);
    }

    final imageUrl = _arasaacService.getStaticImageUrlWithSize(pictogramId, size: sizes[currentIndex]);
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'image/png,image/webp,image/*,*/*',
        'Accept-Language': 'en-US,en;q=0.9,nl;q=0.8',
      },
      maxWidthDiskCache: sizes[currentIndex],
      maxHeightDiskCache: sizes[currentIndex],
      memCacheWidth: sizes[currentIndex],
      memCacheHeight: sizes[currentIndex],
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.primaryBlue,
          ),
          strokeWidth: 4,
        ),
      ),
      errorWidget: (context, url, error) {
        // Try next size in the list
        return _buildImageWithFallbackSizes(pictogramId, sizes, currentIndex + 1, fallbackIcon);
      },
      fit: BoxFit.contain,
    );
  }

  Widget _buildFallbackIcon(IconData icon) {
    return Center(
      child: Icon(
        icon,
        size: 120,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  IconData _getIconForKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    if (lowerKeyword.contains('eten') || lowerKeyword.contains('drink') || lowerKeyword.contains('food')) {
      return Icons.restaurant;
    } else if (lowerKeyword.contains('toilet') || lowerKeyword.contains('wc')) {
      return Icons.wc;
    } else if (lowerKeyword.contains('slapen') || lowerKeyword.contains('bed')) {
      return Icons.bed;
    } else if (lowerKeyword.contains('spelen') || lowerKeyword.contains('spel')) {
      return Icons.toys;
    } else if (lowerKeyword.contains('buiten') || lowerKeyword.contains('buiten')) {
      return Icons.park;
    } else {
      return Icons.image_outlined;
    }
  }
}
