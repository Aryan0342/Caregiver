import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/client_profile_model.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../providers/language_provider.dart';
import '../providers/client_session_provider.dart';
import '../services/client_service.dart';
import '../services/set_service.dart';
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
  final ClientService _clientService = ClientService();
  final SetService _setService = SetService();
  late PictogramSet _activeSet;
  List<ClientProfile> _sidebarClients = <ClientProfile>[];
  bool _isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    _activeSet = widget.set;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSidebarClients();
    });
  }

  Future<void> _loadSidebarClients() async {
    try {
      final fetchedClients = await _clientService.getUserClients().first;
      if (!mounted) return;

      final selectedClients = fetchedClients.take(3).toList();
      final controller = ClientSessionProvider.of(context);
      final preferredClientId = _activeSet.clientId;

      final initialClientId = selectedClients.isNotEmpty
          ? (preferredClientId != null &&
                  selectedClients
                      .any((client) => client.id == preferredClientId)
              ? preferredClientId
              : selectedClients.first.id)
          : null;

      setState(() {
        _sidebarClients = selectedClients;
        _isLoadingClients = false;
      });

      if (initialClientId != null) {
        final cloudIndex = await _clientService.getClientProgress(
          clientId: initialClientId,
          setId: _activeSet.id,
        );
        controller.activateClient(initialClientId, index: cloudIndex);
        final restoredIndex = controller.progressFor(initialClientId);
        final pictograms = _modifiedSequence ?? _activeSet.pictograms;
        final maxIndex = pictograms.isEmpty ? 0 : pictograms.length - 1;
        if (mounted) {
          setState(() {
            _currentStepIndex = restoredIndex.clamp(0, maxIndex);
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sidebarClients = <ClientProfile>[];
        _isLoadingClients = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: SizedBox(
            width: 92,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openClientSwitcherPopup,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              AppTheme.primaryBlue,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/images/noun-switch-user-1892509.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        localizations.switchClientActionLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: GestureDetector(
                  onTap: _modifySequence,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: AppTheme.accentOrange, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        localizations.modify,
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              _buildMainContentWithoutButtons(),
              _buildHiddenExitAreas(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openClientSwitcherPopup() async {
    if (_isLoadingClients || _sidebarClients.isEmpty) {
      return;
    }

    final localizations = LanguageProvider.localizationsOf(context);
    final controller = ClientSessionProvider.of(context);
    final initialIndex = _sidebarClients.indexWhere(
      (client) => client.id == controller.activeClientId,
    );
    final pageController = PageController(
      viewportFraction: 0.9,
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: localizations.switchClient,
        barrierColor: Colors.black.withValues(alpha: 0.14),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Material(
                      color: Colors.white,
                      elevation: 20,
                      borderRadius: BorderRadius.circular(26),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 28,
                              child: Stack(
                                children: [
                                  Center(
                                    child: Text(
                                      localizations.switchClient,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              localizations.swipeChooseAnotherClient,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: PageView.builder(
                                controller: pageController,
                                itemCount: _sidebarClients.length,
                                itemBuilder: (context, index) {
                                  final client = _sidebarClients[index];
                                  final isActive =
                                      controller.activeClientId == client.id;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: _buildSwitcherCard(
                                      context,
                                      client: client,
                                      isActive: isActive,
                                      onSelect: () {
                                        Navigator.of(dialogContext).pop();
                                        unawaited(_switchClient(client.id));
                                      },
                                    ),
                                  );
                                },
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
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      );
    } finally {
      pageController.dispose();
    }
  }

  Future<void> _switchClient(String nextClientId) async {
    final controller = ClientSessionProvider.of(context);
    final currentClientId = controller.activeClientId;
    final selectedSet = await _chooseSetForClient(nextClientId);
    if (selectedSet == null) return;

    if (currentClientId != null) {
      unawaited(_persistClientProgress(currentClientId, _currentStepIndex));
    }

    controller.switchClient(nextClientId, currentIndex: _currentStepIndex);

    final cloudIndex = await _clientService.getClientProgress(
      clientId: nextClientId,
      setId: selectedSet.id,
    );
    controller.activateClient(nextClientId, index: cloudIndex);

    final pictograms = selectedSet.pictograms;
    final maxIndex = pictograms.isEmpty ? 0 : pictograms.length - 1;

    if (!mounted) return;
    setState(() {
      _activeSet = selectedSet;
      _modifiedSequence = null;
      _currentStepIndex = cloudIndex.clamp(0, maxIndex);
    });
  }

  Future<PictogramSet?> _chooseSetForClient(String clientId) async {
    final localizations = LanguageProvider.localizationsOf(context);
    final sets = await _setService.getUserSetsOnce(
      clientId: clientId,
      includeAutoSaved: true,
    );

    if (sets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.noSetsForClient),
            backgroundColor: AppTheme.accentOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }

    PictogramSet? currentActiveSet;
    for (final set in sets) {
      if (set.id == _activeSet.id) {
        currentActiveSet = set;
        break;
      }
    }
    final withoutCurrent =
        sets.where((set) => set.id != _activeSet.id).toList();
    final recentSets = withoutCurrent.take(5).toList();
    final olderSets = withoutCurrent.skip(5).toList();

    if (currentActiveSet != null) {
      recentSets.insert(0, currentActiveSet);
    }

    if (!mounted) return null;
    return showModalBottomSheet<PictogramSet>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.chooseSetForClient,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        localizations.activePictogramSets,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      for (final set in recentSets) ...[
                        _buildSetPickerTile(
                          sheetContext,
                          set,
                          isCurrentSet: set.id == _activeSet.id,
                        ),
                        const Divider(height: 1),
                      ],
                      if (olderSets.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          localizations.myPictogramSets,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        for (final set in olderSets) ...[
                          _buildSetPickerTile(sheetContext, set),
                          const Divider(height: 1),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetPickerTile(
    BuildContext sheetContext,
    PictogramSet set, {
    bool isCurrentSet = false,
  }) {
    return ListTile(
      title: Text(
        set.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${set.pictograms.length} pictogrammen',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCurrentSet
          ? Icon(
              Icons.check_circle,
              color: AppTheme.primaryBlue,
            )
          : null,
      onTap: () => Navigator.of(sheetContext).pop(set),
    );
  }

  Future<void> _persistClientProgress(String clientId, int index) async {
    try {
      await _clientService.saveClientProgress(
        clientId: clientId,
        setId: _activeSet.id,
        index: index,
      );
    } catch (_) {
      // Keep the session usable even if cloud sync is unavailable.
    }
  }

  String _maskClientName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '***';
    if (trimmed.length <= 4) return trimmed;
    return trimmed.substring(0, 4);
  }

  Widget _buildSwitcherCard(
    BuildContext context, {
    required ClientProfile client,
    required bool isActive,
    required VoidCallback onSelect,
  }) {
    final localizations = LanguageProvider.localizationsOf(context);
    final displayName = _maskClientName(client.name);
    final avatarText = displayName.isNotEmpty ? displayName[0] : 'C';

    return Material(
      color: isActive
          ? AppTheme.primaryBlue.withValues(alpha: 0.06)
          : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onSelect,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryBlue.withValues(alpha: 0.32)
                  : AppTheme.primaryBlue.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.92),
                      AppTheme.primaryBlueLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                isActive
                    ? localizations.activeClient
                    : localizations.tapToSwitch,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isActive ? AppTheme.primaryBlue : AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 52),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(localizations.chooseClient),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentWithoutButtons() {
    final localizations = LanguageProvider.localizationsOf(context);

    // Use modified sequence if available, otherwise use original
    final pictograms = _modifiedSequence ?? _activeSet.pictograms;

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
    final pictograms = _modifiedSequence ?? _activeSet.pictograms;
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

    final pictograms = _modifiedSequence ?? _activeSet.pictograms;
    if (_currentStepIndex < pictograms.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      final controller = ClientSessionProvider.of(context);
      controller.updateCurrentIndex(_currentStepIndex);
      final activeClientId = controller.activeClientId;
      if (activeClientId != null) {
        unawaited(_persistClientProgress(activeClientId, _currentStepIndex));
      }
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      final controller = ClientSessionProvider.of(context);
      controller.updateCurrentIndex(_currentStepIndex);
      final activeClientId = controller.activeClientId;
      if (activeClientId != null) {
        unawaited(_persistClientProgress(activeClientId, _currentStepIndex));
      }
    }
  }

  void _modifySequence() async {
    final currentSequence =
        _modifiedSequence ?? List<Pictogram>.from(_activeSet.pictograms);

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

      final controller = ClientSessionProvider.of(context);
      controller.updateCurrentIndex(0);
      final activeClientId = controller.activeClientId;
      if (activeClientId != null) {
        unawaited(_persistClientProgress(activeClientId, 0));
      }

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

  void _removePictogram(int index) {
    setState(() {
      _modifiedSequence.removeAt(index);
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

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 700, maxWidth: 800),
        child: AlertDialog(
          title: Text(localizations.modifySequence),
          content: Column(
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
        ),
      ),
    );
  }

  Widget _buildPictogramListItem(Pictogram pictogram, int index) {
    return Dismissible(
      key: ValueKey('${pictogram.id}-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.red[400],
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      onDismissed: (_) => _removePictogram(index),
      child: Card(
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            maxLines: 3,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          subtitle: Text('Stap ${index + 1}'),
          trailing: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}
