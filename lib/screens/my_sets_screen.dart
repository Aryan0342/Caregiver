import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../services/set_service.dart';
import '../services/pictogram_pdf_service.dart';
import '../services/set_share_service.dart';
import 'edit_set_screen.dart';
import 'client_mode_session_screen.dart';
import '../providers/language_provider.dart';

enum _SetMenuAction { exportPdf, shareLink, delete }

class MySetsScreen extends StatefulWidget {
  const MySetsScreen({super.key});

  @override
  State<MySetsScreen> createState() => _MySetsScreenState();
}

class _MySetsScreenState extends State<MySetsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final setService = SetService();
    final pdfService = PictogramPdfService();
    final shareService = SetShareService();
    final localizations = LanguageProvider.localizationsOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.myPictogramSets),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Tab buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                // Tab 1: Saved sets
                Expanded(
                  child: _buildTabButton(
                    context,
                    0,
                    localizations.savedSets,
                  ),
                ),
                const SizedBox(width: 8),
                // Tab 2: Last 5 auto-saved sets
                Expanded(
                  child: _buildTabButton(
                    context,
                    1,
                    localizations.recentAutoSaved,
                  ),
                ),
                const SizedBox(width: 8),
                // Tab 3: Import
                Expanded(
                  child: _buildTabButton(
                    context,
                    2,
                    localizations.importPictogramSet,
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: _buildTabContent(
              context,
              setService,
              pdfService,
              shareService,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, int tabIndex, String label) {
    final isSelected = _selectedTabIndex == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = tabIndex;
        });
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    SetService setService,
    PictogramPdfService pdfService,
    SetShareService shareService,
  ) {
    if (_selectedTabIndex == 0) {
      return _buildSavedSetsTab(context, setService, pdfService, shareService);
    } else if (_selectedTabIndex == 1) {
      return _buildAutoSavedTab(context, setService, pdfService, shareService);
    } else {
      return _buildImportTab(context, shareService);
    }
  }

  Widget _buildSavedSetsTab(
    BuildContext context,
    SetService setService,
    PictogramPdfService pdfService,
    SetShareService shareService,
  ) {
    return StreamBuilder<List<PictogramSet>>(
      stream: setService.getUserSets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          final errorMessage = snapshot.error.toString();
          final isOffline = errorMessage.toLowerCase().contains('offline') ||
              errorMessage.toLowerCase().contains('network') ||
              errorMessage.toLowerCase().contains('unavailable');
          final isIndexBuilding = errorMessage
                  .toLowerCase()
                  .contains('index') &&
              (errorMessage.toLowerCase().contains('building') ||
                  errorMessage.toLowerCase().contains('failed-precondition'));

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOffline
                        ? Icons.cloud_off
                        : isIndexBuilding
                            ? Icons.hourglass_empty
                            : Icons.error_outline,
                    size: 64,
                    color: isOffline
                        ? AppTheme.accentOrange
                        : isIndexBuilding
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final localizations =
                          LanguageProvider.localizationsOf(context);
                      return Column(
                        children: [
                          Text(
                            isOffline
                                ? localizations.offlineModeMessage
                                : isIndexBuilding
                                    ? localizations.indexBuilding
                                    : localizations.errorLoadingSets,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isOffline
                                ? localizations.offlineMessage
                                : isIndexBuilding
                                    ? localizations.indexBuildingMessage
                                    : errorMessage.length > 200
                                        ? errorMessage.substring(0, 200) + "..."
                                        : errorMessage,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        final sets = snapshot.data ?? [];

        if (sets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 80,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final localizations =
                        LanguageProvider.localizationsOf(context);
                    return Column(
                      children: [
                        Text(
                          localizations.noSets,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.createFirstSet,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final set = sets[index];
            return _buildSetCard(
              context,
              set,
              pdfService,
              shareService,
            );
          },
        );
      },
    );
  }

  Widget _buildAutoSavedTab(
    BuildContext context,
    SetService setService,
    PictogramPdfService pdfService,
    SetShareService shareService,
  ) {
    return StreamBuilder<List<PictogramSet>>(
      stream: setService.getAutoSavedSets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final autoSavedSets = snapshot.data ?? [];

        if (autoSavedSets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final localizations =
                        LanguageProvider.localizationsOf(context);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            localizations.noAutoSavedSets,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.autoSavedExplanation,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: autoSavedSets.length,
          itemBuilder: (context, index) {
            final set = autoSavedSets[index];
            return _buildSetCard(
              context,
              set,
              pdfService,
              shareService,
            );
          },
        );
      },
    );
  }

  Widget _buildImportTab(
    BuildContext context,
    SetShareService shareService,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_rounded,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final localizations =
                      LanguageProvider.localizationsOf(context);
                  return Column(
                    children: [
                      Text(
                        localizations.importSet,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.pasteShareLink,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_link),
                        label: Text(localizations.importPictogramSet),
                        onPressed: () =>
                            _showImportDialog(context, shareService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetCard(
    BuildContext context,
    PictogramSet set,
    PictogramPdfService pdfService,
    SetShareService shareService,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Set name and step count
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        set.name.isEmpty ? 'Auto-saved set' : set.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final localizations =
                              LanguageProvider.localizationsOf(context);
                          return Text(
                            '${set.stepCount} ${localizations.steps}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_SetMenuAction>(
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: LanguageProvider.localizationsOf(context).shareSet,
                  onSelected: (action) => _handleSetMenuAction(
                    context,
                    set,
                    action,
                    pdfService,
                    shareService,
                  ),
                  itemBuilder: (context) {
                    final localizations =
                        LanguageProvider.localizationsOf(context);
                    return [
                      PopupMenuItem(
                        value: _SetMenuAction.exportPdf,
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, size: 18),
                            const SizedBox(width: 8),
                            Text(localizations.exportPdf),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _SetMenuAction.shareLink,
                        child: Row(
                          children: [
                            const Icon(Icons.share, size: 18),
                            const SizedBox(width: 8),
                            Text(localizations.shareSet),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _SetMenuAction.delete,
                        child: Row(
                          children: [
                            const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              localizations.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pictogram preview (horizontal scroll)
            if (set.pictograms.isNotEmpty)
              SizedBox(
                height: 68,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: set.pictograms.length,
                  itemBuilder: (context, index) {
                    return _buildPictogramPreview(
                      context,
                      set.pictograms[index],
                      index,
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Action buttons
            if (set.isAutoSaved)
              // Auto-saved set buttons: Save Permanently + Start
              Row(
                children: [
                  // Save Permanently button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 18),
                      label: Builder(
                        builder: (context) {
                          final localizations =
                              LanguageProvider.localizationsOf(context);
                          return Text(
                            localizations.savePermanently,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _savePermanently(context, set),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Start button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Builder(
                        builder: (context) {
                          final localizations =
                              LanguageProvider.localizationsOf(context);
                          return Text(
                            localizations.startSequence,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ClientModeSessionScreen(set: set),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            else
              // Regular saved set buttons: Edit + Start
              Row(
                children: [
                  // Edit button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: Builder(
                        builder: (context) {
                          final localizations =
                              LanguageProvider.localizationsOf(context);
                          return Text(
                            localizations.edit,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSetScreen(set: set),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Start button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Builder(
                        builder: (context) {
                          final localizations =
                              LanguageProvider.localizationsOf(context);
                          return Text(
                            localizations.startSequence,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ClientModeSessionScreen(set: set),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSetMenuAction(
    BuildContext context,
    PictogramSet set,
    _SetMenuAction action,
    PictogramPdfService pdfService,
    SetShareService shareService,
  ) async {
    final localizations = LanguageProvider.localizationsOf(context);

    try {
      if (action == _SetMenuAction.exportPdf) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryBlue),
                    const SizedBox(height: 16),
                    Text(
                      'PDF genereren...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await pdfService.printSet(set);

        // Close loading indicator
        if (context.mounted) Navigator.of(context).pop();
        return;
      }

      if (action == _SetMenuAction.shareLink) {
        final link = await shareService.createShareLink(set);
        try {
          final result = await Share.share(
            '${set.name}\n$link',
            subject: localizations.shareSet,
          );
          if (result.status == ShareResultStatus.dismissed) {
            // User dismissed the share sheet, no error
            return;
          }
        } on Exception catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('${localizations.shareSet} ${localizations.failed}: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return;
        }
      } else if (action == _SetMenuAction.delete) {
        // Show confirmation dialog
        final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(localizations.delete),
                content: Text(
                  '${localizations.areYouSure} ${set.name}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      localizations.cancel,
                      style: TextStyle(color: AppTheme.primaryBlue),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      localizations.delete,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldDelete && context.mounted) {
          try {
            await SetService().deleteSet(set.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${set.name} ${localizations.deleted}'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              setState(() {});
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.deleteFailed),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
        }
        return;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.importFailed),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _showImportDialog(
    BuildContext context,
    SetShareService shareService,
  ) async {
    final localizations = LanguageProvider.localizationsOf(context);
    final controller = TextEditingController();

    final token = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.importSet),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: localizations.pasteShareLink,
            prefixIcon: const Icon(Icons.link_rounded),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(localizations.importAction),
          ),
        ],
      ),
    );

    if (token == null || token.isEmpty) return;

    try {
      await shareService.importSharedSet(token);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.importSuccess),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.importFailed),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildPictogramPreview(
    BuildContext context,
    Pictogram pictogram,
    int index,
  ) {
    return Container(
      width: 64,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pictogram image
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: pictogram.imageUrl.isNotEmpty
                  ? Image.network(
                      pictogram.imageUrl,
                      fit: BoxFit.cover,
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
                        size: 22,
                        color: AppTheme.primaryBlue,
                      ),
                    )
                  : Icon(
                      _getIconForKeyword(pictogram.keyword),
                      size: 22,
                      color: AppTheme.primaryBlue,
                    ),
            ),
          ),
          const SizedBox(height: 2),
          // Step number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            constraints: const BoxConstraints(
              minHeight: 12,
              maxHeight: 14,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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
    } else if (lowerKeyword.contains('ontbijt') ||
        lowerKeyword.contains('eten')) {
      return Icons.restaurant;
    } else if (lowerKeyword.contains('tanden') ||
        lowerKeyword.contains('poets')) {
      return Icons.cleaning_services;
    } else if (lowerKeyword.contains('school')) {
      return Icons.school;
    }
    return Icons.image_outlined;
  }

  Future<void> _savePermanently(BuildContext context, PictogramSet set) async {
    final localizations = LanguageProvider.localizationsOf(context);
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.namingGuide),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: localizations.giveAName,
            prefixIcon: const Icon(Icons.label_outline),
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final enteredName = nameController.text.trim();
              if (enteredName.isNotEmpty) {
                Navigator.of(context).pop(enteredName);
              } else {
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
              }
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

    if (name != null && name.isNotEmpty && context.mounted) {
      try {
        final setService = SetService();
        // Update the set with the new name and mark as not auto-saved
        final updatedSet = set.copyWith(
          name: name,
          isAutoSaved: false,
        );
        await setService.updateSet(updatedSet);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.save}: $name'),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.importFailed),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
      nameController.dispose();
    }
  }
}
