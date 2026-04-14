import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/client_profile_model.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../services/client_service.dart';

class ClientDetailsScreen extends StatefulWidget {
  final ClientProfile client;

  const ClientDetailsScreen({
    super.key,
    required this.client,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  final ClientService _clientService = ClientService();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.client.name;
    _phoneController.text = widget.client.phoneNumber ?? '';
    _emailController.text = widget.client.email ?? '';
    _noteController.text = widget.client.note ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final localizations = LanguageProvider.localizationsOf(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final normalizedName = _normalizeName(_nameController.text);
      await _clientService.updateClient(
        clientId: widget.client.id,
        name: normalizedName,
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        note: _noteController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.currentLanguage == AppLanguage.dutch
                ? 'Client bijgewerkt'
                : 'Client updated',
          ),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.currentLanguage == AppLanguage.dutch
                ? 'Kon client niet bijwerken'
                : 'Could not update client',
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
        title: Text(
          localizations.currentLanguage == AppLanguage.dutch
              ? 'Client details'
              : 'Client details',
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            tooltip: _isEditing
                ? (localizations.currentLanguage == AppLanguage.dutch
                    ? 'Annuleren'
                    : 'Cancel')
                : (localizations.currentLanguage == AppLanguage.dutch
                    ? 'Bewerken'
                    : 'Edit'),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isEditing
            ? _buildEditForm(localizations)
            : _buildDetailsView(localizations),
      ),
    );
  }

  Widget _buildDetailsView(AppLocalizations localizations) {
    final name = _nameController.text.trim();
    final displayName = _displayInitials(name);
    final initials = _buildInitials(name);
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final note = _noteController.text.trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryBlueLight,
                  foregroundColor: AppTheme.primaryBlue,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isEmpty
                            ? (localizations.currentLanguage ==
                                    AppLanguage.dutch
                                ? 'Geen naam'
                                : 'No name')
                            : displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.currentLanguage == AppLanguage.dutch
                            ? 'Client details'
                            : 'Client details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          title: localizations.currentLanguage == AppLanguage.dutch
              ? 'Contact'
              : 'Contact',
          children: [
            _buildDetailItem(
              icon: Icons.phone_outlined,
              label: localizations.currentLanguage == AppLanguage.dutch
                  ? 'Telefoonnummer'
                  : 'Phone number',
              value: phone.isEmpty
                  ? (localizations.currentLanguage == AppLanguage.dutch
                      ? 'Niet opgegeven'
                      : 'Not provided')
                  : phone,
            ),
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.email_outlined,
              label: localizations.currentLanguage == AppLanguage.dutch
                  ? 'E-mail'
                  : 'Email',
              value: email.isEmpty
                  ? (localizations.currentLanguage == AppLanguage.dutch
                      ? 'Niet opgegeven'
                      : 'Not provided')
                  : email,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          title: localizations.currentLanguage == AppLanguage.dutch
              ? 'Notitie'
              : 'Note',
          children: [
            Text(
              note.isEmpty
                  ? (localizations.currentLanguage == AppLanguage.dutch
                      ? 'Geen notitie'
                      : 'No note')
                  : note,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: note.isEmpty
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(AppLocalizations localizations) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTextField(
            controller: _nameController,
            label: localizations.currentLanguage == AppLanguage.dutch
                ? 'Client naam'
                : 'Client name',
            required: true,
            enabled: _isEditing,
            maxLength: 4,
            inputFormatters: [
              LengthLimitingTextInputFormatter(4),
            ],
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: localizations.currentLanguage == AppLanguage.dutch
                ? 'Telefoonnummer (optioneel)'
                : 'Phone number (optional)',
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: localizations.currentLanguage == AppLanguage.dutch
                ? 'E-mail (optioneel)'
                : 'Email (optional)',
            keyboardType: TextInputType.emailAddress,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _noteController,
            label: localizations.currentLanguage == AppLanguage.dutch
                ? 'Notitie (optioneel)'
                : 'Note (optional)',
            maxLines: 4,
            enabled: _isEditing,
          ),
          const SizedBox(height: 24),
          if (_isEditing)
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlueLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    final first = parts.first.substring(0, 1).toUpperCase();
    final second =
        parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
    return '$first$second';
  }

  String _displayInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 4) return trimmed;
    return trimmed.substring(0, 4);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
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
