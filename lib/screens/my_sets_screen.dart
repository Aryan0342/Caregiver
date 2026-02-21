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

enum _SetMenuAction { exportPdf, shareLink }

class MySetsScreen extends StatelessWidget {
  const MySetsScreen({super.key});

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
        actions: [
          IconButton(
            icon: const Icon(Icons.link_rounded),
            tooltip: localizations.importSet,
            onPressed: () => _showImportDialog(context, shareService),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<PictogramSet>>(
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
                                          ? errorMessage.substring(0, 200) +
                                              "..."
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
            padding: const EdgeInsets.all(16),
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
                        set.name,
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
                    final pictogram = set.pictograms[index];
                    return _buildPictogramPreview(
                      context,
                      pictogram,
                      index,
                    );
                  },
                ),
              )
            else
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Builder(
                    builder: (context) {
                      final localizations =
                          LanguageProvider.localizationsOf(context);
                      return Text(
                        localizations.noPictograms,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Edit button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSetScreen(set: set),
                        ),
                      ).then((saved) {
                        if (saved == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Builder(
                                builder: (context) => Text(
                                    LanguageProvider.localizationsOf(context)
                                        .setUpdated),
                              ),
                              backgroundColor: AppTheme.accentGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Builder(
                      builder: (context) => Text(
                        LanguageProvider.localizationsOf(context).edit,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Pictoreeks starten button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClientModeSessionScreen(set: set),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Builder(
                      builder: (context) => Text(
                        LanguageProvider.localizationsOf(context)
                            .startPictoreeks,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      backgroundColor: AppTheme.accentGreen,
                      minimumSize: const Size(0, 40),
                    ),
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
        await pdfService.printSet(set);
        return;
      }

      final link = await shareService.createShareLink(set);
      await Share.share('${set.name}\n$link');
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
                      pictogram.imageUrl, // Cloudinary URL
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
}
