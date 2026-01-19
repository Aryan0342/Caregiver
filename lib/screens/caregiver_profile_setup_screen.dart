import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/caregiver_profile_service.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../routes/app_routes.dart';

/// Caregiver profile setup screen.
/// 
/// Allows caregivers to set up their profile after registration.
/// Saves data to Firestore collection 'caregivers' with Firebase UID as document ID.
class CaregiverProfileSetupScreen extends StatefulWidget {
  const CaregiverProfileSetupScreen({super.key});

  @override
  State<CaregiverProfileSetupScreen> createState() => _CaregiverProfileSetupScreenState();
}

class _CaregiverProfileSetupScreenState extends State<CaregiverProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organisationController = TextEditingController();
  final _locationController = TextEditingController();
  final _profileService = CaregiverProfileService();
  final _authService = AuthService();
  
  String? _selectedRole;
  String? _selectedSex;
  String _selectedLanguage = 'nl';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCaregiverName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organisationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Load caregiver name from Firebase Auth display name or email
  void _loadCaregiverName() {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? user.email?.split('@').first ?? '';
    }
  }

  /// Handle profile save
  Future<void> _handleSaveProfile() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form (only role is required)
    if (_selectedRole == null || _selectedRole!.isEmpty) {
      setState(() {
        _errorMessage = 'Selecteer uw rol';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save profile to Firestore
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

        // Navigate to PIN setup screen
        Navigator.pushReplacementNamed(context, AppRoutes.createCaregiverPin);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Handle skip (save with minimal data)
  Future<void> _handleSkip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save with default values
      await _profileService.saveProfile(
        name: _nameController.text.trim().isEmpty 
            ? 'Caregiver' 
            : _nameController.text.trim(),
        role: _selectedRole ?? 'Parent',
        language: _selectedLanguage,
      );

      if (mounted) {
        // Navigate to PIN setup screen
        Navigator.pushReplacementNamed(context, AppRoutes.createCaregiverPin);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.profileSetup),
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
                  minHeight: constraints.maxHeight - 48, // Account for padding
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                const SizedBox(height: 20),
                
                // Description
                Text(
                  localizations.profileSetupDescription,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Role dropdown (required)
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
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  dropdownColor: AppTheme.surfaceWhite,
                  menuMaxHeight: 200,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'Parent',
                      child: Text(
                        localizations.roleParent,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Teacher',
                      child: Text(
                        localizations.roleTeacher,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Therapist',
                      child: Text(
                        localizations.roleTherapist,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                  value: _selectedRole,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Name field
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
                
                // Sex dropdown (optional)
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
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  dropdownColor: AppTheme.surfaceWhite,
                  menuMaxHeight: 200,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'Male',
                      child: Text(
                        localizations.sexMale,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Female',
                      child: Text(
                        localizations.sexFemale,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text(
                        localizations.sexOther,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSex = value;
                    });
                  },
                  value: _selectedSex,
                ),
                const SizedBox(height: 24),
                
                // Organisation field (optional)
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
                
                // Location field (optional)
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
                
                // Language dropdown (default: nl)
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
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  dropdownColor: AppTheme.surfaceWhite,
                  menuMaxHeight: 200,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'nl',
                      child: const Text(
                        'Nederlands',
                        style: TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: const Text(
                        'English',
                        style: TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                    }
                  },
                  value: _selectedLanguage,
                ),
                const SizedBox(height: 32),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
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
                
                // Save Profile button
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                const SizedBox(height: 16),
                
                // Skip button (optional)
                TextButton(
                  onPressed: _isLoading ? null : _handleSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    localizations.skip,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
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
}
