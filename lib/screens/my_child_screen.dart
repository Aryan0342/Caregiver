import 'package:flutter/material.dart';
import '../models/set_model.dart';
import '../theme.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';
import '../services/set_service.dart';
import '../routes/app_routes.dart';
import 'client_mode_session_screen.dart';
import 'pictogram_picker_screen.dart';

class MyChildScreen extends StatefulWidget {
  const MyChildScreen({super.key});

  @override
  State<MyChildScreen> createState() => _MyChildScreenState();
}

class _MyChildScreenState extends State<MyChildScreen> {
  final SetService _setService = SetService();

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    final isDutch = localizations.currentLanguage == AppLanguage.dutch;

    final title = isDutch ? 'Mijn kind' : 'My child';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: const SizedBox(height: 24),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 70),
                          _buildMainActionButton(
                            context,
                            icon: Icons.add_rounded,
                            title: localizations.newPictogramSet,
                            color: AppTheme.accentOrange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PictogramPickerScreen(
                                    maxSelection: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMainActionButton(
                            context,
                            icon: Icons.folder_rounded,
                            title: localizations.myPictogramSets,
                            color: AppTheme.primaryBlue,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.mySets);
                            },
                          ),
                          const SizedBox(height: 32),
                          _buildCompactActiveCard(context),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          constraints: const BoxConstraints(minHeight: 68),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        height: 1.25,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActiveCard(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    final isDutch = localizations.currentLanguage == AppLanguage.dutch;
    final subtitleText = isDutch
        ? 'Hervat eenvoudig je laatste actieve pictoreeksen.'
        : 'Resume your latest active pictogram sets with one tap.';
    final buttonText =
        isDutch ? 'Bekijk de laatste reeksen' : 'View recent sequences';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        localizations.activePictogramSets,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitleText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.3,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openActiveSetChooser,
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 14),
                    label: Text(
                      buttonText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openActiveSetChooser() async {
    final localizations = LanguageProvider.localizationsOf(context);
    final allSets = await _setService.getUserSetsOnce(includeAutoSaved: true);
    final activeSets = allSets.where((set) => set.isAutoSaved).take(5).toList();

    if (!mounted) return;

    if (activeSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.noAutoSavedSets),
          backgroundColor: AppTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedSet = await showModalBottomSheet<PictogramSet>(
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
                  localizations.activePictogramSets,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeSets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (itemContext, index) {
                      final set = activeSets[index];
                      final displayName = set.name.trim().isEmpty
                          ? '${localizations.recentAutoSaved} ${index + 1}'
                          : set.name;
                      final clientName =
                          set.clientName?.trim().isNotEmpty == true
                              ? set.clientName!.trim()
                              : null;

                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primaryBlue.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.flash_on_rounded,
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        title: Text(
                          clientName ?? displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        subtitle: Text(
                          clientName == null
                              ? '${set.pictograms.length} picto\'s'
                              : '${localizations.currentLanguage == AppLanguage.dutch ? 'Pictoreeks' : 'Pictogram set'}: $displayName • ${set.pictograms.length} picto\'s',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        trailing: Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppTheme.accentGreen,
                          size: 26,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext, set);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSet == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientModeSessionScreen(set: selectedSet),
      ),
    );
  }
}
