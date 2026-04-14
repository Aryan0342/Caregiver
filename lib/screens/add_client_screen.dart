import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';
import '../services/client_service.dart';
import '../routes/app_routes.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ClientService _clientService = ClientService();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (_isSaving) return;
    final localizations = LanguageProvider.localizationsOf(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final normalizedName = _normalizeName(_nameController.text);
      await _clientService.createClient(
        name: normalizedName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.currentLanguage == AppLanguage.dutch
                ? 'Client aangemaakt'
                : 'Client created',
          ),
          backgroundColor: AppTheme.accentGreen,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.clients,
        (route) => route.isFirst,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.currentLanguage == AppLanguage.dutch
                ? 'Kon client niet aanmaken'
                : 'Could not create client',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.addClient),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildTextField(
                controller: _nameController,
                label: localizations.currentLanguage == AppLanguage.dutch
                    ? 'Cliënt naam'
                    : 'Client name',
                required: true,
                maxLength: 4,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4),
                ],
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        localizations.currentLanguage == AppLanguage.dutch
                            ? 'Opslaan'
                            : 'Save',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        helperText: required
            ? (LanguageProvider.localizationsOf(context).currentLanguage ==
                    AppLanguage.dutch
                ? 'Gebruik maximaal 4 tekens, zoals initialen. Dit helpt de privacy van de client te beschermen.'
                : 'Use a maximum of 4 characters, such as initials. This helps protect the client\'s privacy.')
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        counterText: maxLength != null ? '' : null,
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return LanguageProvider.localizationsOf(context)
                            .currentLanguage ==
                        AppLanguage.dutch
                    ? 'Naam is verplicht'
                    : 'Name is required';
              }
              return null;
            }
          : null,
    );
  }

  String _normalizeName(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 4) return trimmed;
    return trimmed.substring(0, 4);
  }
}
