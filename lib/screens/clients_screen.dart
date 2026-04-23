import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/client_profile_model.dart';
import '../models/set_model.dart';
import '../services/client_service.dart';
import '../services/set_service.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';
import '../routes/app_routes.dart';
import 'my_sets_screen.dart';
import 'pictogram_picker_screen.dart';
import 'client_details_screen.dart';
import 'client_mode_session_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientService _clientService = ClientService();
  final SetService _setService = SetService();

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.myClients),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: localizations.addClient,
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addClient);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ClientProfile>>(
        stream: _clientService.getUserClients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  localizations.currentLanguage == AppLanguage.dutch
                      ? 'Fout bij laden van cliënten'
                      : 'Error loading clients',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final clients = snapshot.data ?? [];
          if (clients.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              _buildResumeActiveCard(context),
              const SizedBox(height: 12),
              for (final client in clients) ...[
                _buildClientCard(context, client),
                const SizedBox(height: 10),
              ],
              _buildAddClientCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumeActiveCard(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    final isDutch = localizations.currentLanguage == AppLanguage.dutch;
    final subtitleText = isDutch
        ? 'Hervat eenvoudig je laatste actieve pictoreeksen.'
        : 'Resume your latest active pictogram sets with one tap.';
    final buttonText =
        isDutch ? 'Bekijk de laatste reeksen' : 'View recent sequences';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.activePictogramSets,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitleText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openActiveSetChooser,
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 15),
                    label: Text(
                      buttonText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
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

  Widget _buildEmptyState(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.addClient);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryBlueLight,
                    child: Icon(
                      Icons.group_outlined,
                      size: 36,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.accentOrange,
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noClientsYet,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.currentLanguage == AppLanguage.dutch
                  ? 'Maak een cliënt aan om pictoreeksen te beheren.'
                  : 'Create a client to manage pictogram sets.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, ClientProfile client) {
    final localizations = LanguageProvider.localizationsOf(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryBlueLight,
                  foregroundColor: AppTheme.primaryBlue,
                  child: const Icon(Icons.person_outline, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _displayInitials(client.name),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                  ),
                ),
                PopupMenuButton<_ClientMenuAction>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => _handleClientMenuAction(
                    context,
                    client,
                    action,
                  ),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: _ClientMenuAction.viewDetails,
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              localizations.currentLanguage == AppLanguage.dutch
                                  ? 'Bekijk details'
                                  : 'View details',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _ClientMenuAction.delete,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              localizations.currentLanguage == AppLanguage.dutch
                                  ? 'Verwijderen'
                                  : 'Delete',
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MySetsScreen(
                            selectedClient: client,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: Text(
                      localizations.currentLanguage == AppLanguage.dutch
                          ? 'Opgeslagen reeksen'
                          : 'Saved sets',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PictogramPickerScreen(
                            maxSelection: 20,
                            selectedClient: client,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      localizations.currentLanguage == AppLanguage.dutch
                          ? 'Nieuwe pictoreeks'
                          : 'New pictogram set',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
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

  Widget _buildAddClientCard(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Center(
        child: SizedBox(
          width: 260,
          height: 60,
          child: Material(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, AppRoutes.addClient),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryBlue,
                    width: 1.6,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        localizations.createNewClient,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ClientMenuAction { viewDetails, delete }

extension on _ClientsScreenState {
  String _displayInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 4) return trimmed;
    return trimmed.substring(0, 4);
  }

  Future<void> _handleClientMenuAction(
    BuildContext context,
    ClientProfile client,
    _ClientMenuAction action,
  ) async {
    final localizations = LanguageProvider.localizationsOf(context);

    if (action == _ClientMenuAction.viewDetails) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDetailsScreen(client: client),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              localizations.currentLanguage == AppLanguage.dutch
                  ? 'Client verwijderen'
                  : 'Delete client',
            ),
            content: Text(
              localizations.currentLanguage == AppLanguage.dutch
                  ? 'Weet u zeker dat u deze client wilt verwijderen?'
                  : 'Are you sure you want to delete this client?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  localizations.currentLanguage == AppLanguage.dutch
                      ? 'Verwijderen'
                      : 'Delete',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await _clientService.deleteClient(client.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.currentLanguage == AppLanguage.dutch
                ? 'Client verwijderd'
                : 'Client deleted',
          ),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.currentLanguage == AppLanguage.dutch
                ? 'Kon client niet verwijderen'
                : 'Could not delete client',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
