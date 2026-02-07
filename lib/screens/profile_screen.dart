import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/caregiver_profile_service.dart';
import '../services/auth_service.dart';
import '../services/set_service.dart';
import '../services/auth_state_service.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';

/// Profile screen - view and edit caregiver account information.
/// Same fields as profile setup: name, role, organisation, location, etc.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organisationController = TextEditingController();
  final _locationController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _profileService = CaregiverProfileService();
  final _authService = AuthService();

  String? _selectedRole;
  String? _selectedSex;
  String? _selectedSecurityQuestion;
  String _selectedLanguage = 'nl';
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _errorMessage;
  bool _hasStoredSecurityAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Normalize sex from Firestore to one of the dropdown values (Male, Female, Other).
  /// Handles casing and Dutch labels (Man/Vrouw/Anders) so the dropdown never crashes.
  String? _normalizeSex(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final lower = value.trim().toLowerCase();
    if (lower == 'male' || lower == 'man') return 'Male';
    if (lower == 'female' || lower == 'vrouw') return 'Female';
    if (lower == 'other' || lower == 'anders') return 'Other';
    if (value == 'Male' || value == 'Female' || value == 'Other') return value;
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organisationController.dispose();
    _locationController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });
    try {
      final data = await _profileService.getProfile();
      if (mounted && data != null) {
        _nameController.text = (data['name'] as String? ?? '').trim();
        _organisationController.text = (data['organisation'] as String? ?? '')
            .trim();
        _locationController.text = (data['location'] as String? ?? '').trim();
        _selectedRole = data['role'] as String?;
        _selectedSex = _normalizeSex(data['sex'] as String?);
        _selectedSecurityQuestion = data['securityQuestion'] as String?;
        _selectedLanguage = data['language'] as String? ?? 'nl';
        _securityAnswerController.text = ''; // Never show stored answer
        // Security question: accept stored value from either language and show in current UI language
        final langService = LanguageService();
        final optsCurrent = AppLocalizations(langService.currentLanguage).securityQuestionOptions;
        final optsOther = AppLocalizations(langService.currentLanguage == AppLanguage.dutch ? AppLanguage.english : AppLanguage.dutch).securityQuestionOptions;
        if (_selectedSecurityQuestion != null && _selectedSecurityQuestion!.isNotEmpty) {
          if (optsCurrent.contains(_selectedSecurityQuestion!)) {
            // Already in current language, keep
          } else {
            final otherIndex = optsOther.indexOf(_selectedSecurityQuestion!);
            if (otherIndex >= 0 && otherIndex < optsCurrent.length) {
              _selectedSecurityQuestion = optsCurrent[otherIndex];
            } else {
              _selectedSecurityQuestion = null;
            }
          }
        } else {
          _selectedSecurityQuestion = null;
        }
        _hasStoredSecurityAnswer = data['securityAnswer'] is String &&
            (data['securityAnswer'] as String).trim().isNotEmpty;
      }
      // If no profile yet, prefill name from auth
      if (mounted && (_nameController.text.isEmpty)) {
        final user = _authService.currentUser;
        if (user != null) {
          _nameController.text =
              user.displayName ?? user.email?.split('@').first ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    setState(() => _errorMessage = null);

    if (_selectedRole == null || _selectedRole!.isEmpty) {
      setState(() {
        _errorMessage = _selectedLanguage == 'nl'
            ? 'Selecteer uw rol'
            : 'Select your role';
      });
      return;
    }
    if (_selectedSecurityQuestion == null ||
        _selectedSecurityQuestion!.isEmpty) {
      setState(() {
        _errorMessage = _selectedLanguage == 'nl'
            ? 'Selecteer een beveiligingsvraag'
            : 'Select a security question';
      });
      return;
    }
    final answer = _securityAnswerController.text.trim();
    if (answer.isNotEmpty && answer.length < 3) {
      setState(() {
        _errorMessage = _selectedLanguage == 'nl'
            ? 'Antwoord moet minimaal 3 tekens zijn'
            : 'Answer must be at least 3 characters';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _profileService.saveProfile(
        name: _nameController.text.trim().isEmpty
            ? 'Caregiver'
            : _nameController.text.trim(),
        role: _selectedRole!,
        sex: _selectedSex,
        organisation: _organisationController.text.trim().isEmpty
            ? null
            : _organisationController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        language: _selectedLanguage,
        securityQuestion: _selectedSecurityQuestion!,
        securityAnswer: answer.isEmpty ? null : answer,
      );
      if (mounted) {
        final localizations = LanguageProvider.localizationsOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.profileSaved),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);

    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(localizations.profileLabel),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.profileLabel),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localizations.profileDescription,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Role
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: localizations.role,
                          hintText: localizations.selectRole,
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        dropdownColor: AppTheme.surfaceWhite,
                        menuMaxHeight: 200,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'begeleider',
                            child: Text(
                              localizations.roleBegeleider,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'persoonlijk begeleider',
                            child: Text(
                              localizations.rolePersoonlijkBegeleider,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'orthopedagoog',
                            child: Text(
                              localizations.roleOrthopedagoog,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ouder',
                            child: Text(
                              localizations.roleOuder,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'anders',
                            child: Text(
                              localizations.roleAnders,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedRole = value),
                        value: _selectedRole,
                        validator: (value) => (value == null || value.isEmpty)
                            ? localizations.fieldRequired
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localizations.caregiverName,
                          hintText: localizations.enterCaregiverName,
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),

                      // Sex
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: localizations.caregiverSex,
                          hintText: localizations.selectSex,
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        dropdownColor: AppTheme.surfaceWhite,
                        menuMaxHeight: 200,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text(
                              localizations.sexMale,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text(
                              localizations.sexFemale,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text(
                              localizations.sexOther,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedSex = value),
                        value: const ['Male', 'Female', 'Other'].contains(_selectedSex)
                            ? _selectedSex
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Organisation
                      TextFormField(
                        controller: _organisationController,
                        decoration: InputDecoration(
                          labelText: localizations.organisation,
                          hintText: localizations.enterOrganisation,
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: localizations.location,
                          hintText: localizations.enterLocation,
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),

                      // Language
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: localizations.languageLabel,
                          prefixIcon: const Icon(Icons.language_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        dropdownColor: AppTheme.surfaceWhite,
                        menuMaxHeight: 200,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'nl',
                            child: Text(
                              'Nederlands',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(
                              'English',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedLanguage = value ?? 'nl'),
                        value: _selectedLanguage,
                      ),
                      const SizedBox(height: 24),

                      // Security Question
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: localizations.securityQuestion,
                          hintText: localizations.selectSecurityQuestion,
                          prefixIcon: const Icon(Icons.security),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        dropdownColor: AppTheme.surfaceWhite,
                        menuMaxHeight: 300,
                        isExpanded: true,
                        items: localizations.securityQuestionOptions.map((
                          question,
                        ) {
                          return DropdownMenuItem(
                            value: question,
                            child: Text(
                              question,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSecurityQuestion = value),
                        value: localizations.securityQuestionOptions.contains(_selectedSecurityQuestion)
                            ? _selectedSecurityQuestion
                            : null,
                        validator: (value) => (value == null || value.isEmpty)
                            ? localizations.fieldRequired
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Security Answer
                      TextFormField(
                        controller: _securityAnswerController,
                        decoration: InputDecoration(
                          labelText: localizations.securityAnswer,
                          hintText: localizations.enterSecurityAnswer,
                          helperText: _hasStoredSecurityAnswer
                              ? localizations.securityAnswerLeaveBlankToKeep
                              : null,
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceWhite,
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(fontSize: 18),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isNotEmpty && v.length < 3)
                            return localizations.securityAnswerTooShort;
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSaveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  localizations.saveProfile,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Delete account section
                      const Divider(height: 32),
                      Text(
                        localizations.deleteAccount,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showDeleteAccountConfirmation(context),
                        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 22),
                        label: Text(
                          localizations.deleteAccount,
                          style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountConfirmation(BuildContext context) async {
    final localizations = LanguageProvider.localizationsOf(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localizations.deleteAccountConfirmTitle),
        content: Text(localizations.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(localizations.cancelDelete, style: TextStyle(color: AppTheme.primaryBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(localizations.confirmDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final password = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(localizations.deleteAccountConfirmTitle),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: localizations.password,
              hintText: localizations.deleteAccountEnterPassword,
            ),
            onSubmitted: (value) => Navigator.of(ctx).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(localizations.cancel, style: TextStyle(color: AppTheme.primaryBlue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(localizations.confirmDelete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (password == null || password.isEmpty || !context.mounted) return;

    try {
      final authStateService = AuthStateService();
      await authStateService.clearLoginStatus();

      final setService = SetService();
      await setService.deleteAllSetsForCurrentUser();

      final profileService = CaregiverProfileService();
      await profileService.deleteProfile();

      final authService = AuthService();
      final result = await authService.deleteAccount(password: password);

      if (!context.mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? localizations.deleteAccountError),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.deleteAccountSuccess),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.deleteAccountError}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
