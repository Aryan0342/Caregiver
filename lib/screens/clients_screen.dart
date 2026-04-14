import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/client_profile_model.dart';
import '../services/client_service.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';
import '../routes/app_routes.dart';
import 'my_sets_screen.dart';
import 'pictogram_picker_screen.dart';
import 'client_details_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientService _clientService = ClientService();

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
