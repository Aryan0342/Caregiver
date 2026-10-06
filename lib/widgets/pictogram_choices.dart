import 'package:flutter/material.dart';
import '../models/pictogram_model.dart';
import '../providers/language_provider.dart';
import '../screens/pictogram_picker_screen.dart';
import '../theme.dart';
import '../utils/pictogram_image.dart';

/// Opens the pictogram picker to choose the options of a choice pictogram.
Future<List<Pictogram>?> pickPictogramChoices(
  BuildContext context,
  Pictogram pictogram,
) {
  return Navigator.push<List<Pictogram>>(
    context,
    MaterialPageRoute(
      builder: (context) => PictogramPickerScreen(
        initialSelection: pictogram.choices,
        maxSelection: 6,
        returnSelection: true,
      ),
    ),
  );
}

/// Button on a set-editor step card to add, edit or remove choice options.
class ChoiceOptionsButton extends StatelessWidget {
  final Pictogram pictogram;
  final ValueChanged<List<Pictogram>> onChanged;

  const ChoiceOptionsButton({
    super.key,
    required this.pictogram,
    required this.onChanged,
  });

  Future<void> _editChoices(BuildContext context) async {
    final selected = await pickPictogramChoices(context, pictogram);
    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    if (!pictogram.hasChoices) {
      return IconButton(
        icon: Icon(Icons.call_split, color: AppTheme.primaryBlue, size: 24),
        onPressed: () => _editChoices(context),
        tooltip: localizations.addChoiceOptions,
        splashRadius: 24,
      );
    }

    return PopupMenuButton<bool>(
      icon: Icon(Icons.call_split, color: AppTheme.accentOrange, size: 24),
      tooltip: localizations.choiceOptions,
      onSelected: (edit) {
        if (edit) {
          _editChoices(context);
        } else {
          onChanged(const []);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: true,
          child: Text(localizations.editChoiceOptions),
        ),
        PopupMenuItem(
          value: false,
          child: Text(localizations.removeChoiceOptions),
        ),
      ],
    );
  }
}

/// Pop-up shown during a session to choose one of the options of
/// [pictogram]. Returns the chosen option, or null when dismissed.
Future<Pictogram?> showPictogramChoiceDialog(
  BuildContext context,
  Pictogram pictogram,
) {
  return showDialog<Pictogram>(
    context: context,
    builder: (dialogContext) {
      final localizations = LanguageProvider.localizationsOf(dialogContext);
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.makeAChoice,
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final option in pictogram.choices)
                      _ChoiceTile(
                        pictogram: option,
                        onTap: () => Navigator.pop(dialogContext, option),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ChoiceTile extends StatelessWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;

  const _ChoiceTile({required this.pictogram, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue, width: 2),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: pictogram.imageUrl.isNotEmpty
                    ? Image(
                        image: pictogramImage(
                            pictogram.imageUrl, PictogramImageSize.small),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: AppTheme.primaryBlue,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                pictogram.keyword,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
