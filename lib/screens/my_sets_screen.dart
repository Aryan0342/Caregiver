import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/set_model.dart';
import '../models/pictogram_model.dart';
import '../services/set_service.dart';
import '../services/arasaac_service.dart';
import 'edit_set_screen.dart';
import 'client_session_screen.dart';

class MySetsScreen extends StatelessWidget {
  const MySetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final setService = SetService();
    final arasaacService = ArasaacService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Mijn pictoreeksen'),
        backgroundColor: AppTheme.primaryBlueLight,
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
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOffline ? Icons.cloud_off : Icons.error_outline,
                      size: 64,
                      color: isOffline ? Colors.orange : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isOffline 
                        ? 'Offline modus'
                        : 'Fout bij laden van pictoreeksen',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOffline
                        ? 'U bent offline. Toon gecachte gegevens of probeer later opnieuw.'
                        : errorMessage.length > 200 
                          ? errorMessage.substring(0, 200) + "..."
                          : errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
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
                  Text(
                    'Geen pictoreeksen',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maak uw eerste pictoreeks aan',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
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
              return _buildSetCard(context, set, arasaacService);
            },
          );
        },
      ),
    );
  }

  Widget _buildSetCard(
    BuildContext context,
    PictogramSet set,
    ArasaacService arasaacService,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Set name and step count
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${set.stepCount} stappen',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pictogram preview (horizontal scroll)
            if (set.pictograms.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: set.pictograms.length,
                  itemBuilder: (context, index) {
                    final pictogram = set.pictograms[index];
                    return _buildPictogramPreview(
                      context,
                      pictogram,
                      index,
                      arasaacService,
                    );
                  },
                ),
              )
            else
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Geen pictogrammen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

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
                              content: const Text('Pictoreeks bijgewerkt'),
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
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Bewerken'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Start met cliënt button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientSessionScreen(set: set),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start met cliënt'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.accentGreen,
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

  Widget _buildPictogramPreview(
    BuildContext context,
    Pictogram pictogram,
    int index,
    ArasaacService arasaacService,
  ) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pictogram image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CachedNetworkImage(
                imageUrl: arasaacService.getStaticImageUrl(pictogram.id),
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  _getIconForKeyword(pictogram.keyword),
                  size: 24,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Step number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
    } else if (lowerKeyword.contains('ontbijt') || lowerKeyword.contains('eten')) {
      return Icons.restaurant;
    } else if (lowerKeyword.contains('tanden') || lowerKeyword.contains('poets')) {
      return Icons.cleaning_services;
    } else if (lowerKeyword.contains('school')) {
      return Icons.school;
    }
    return Icons.image_outlined;
  }
}
