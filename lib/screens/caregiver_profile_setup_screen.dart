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
  final _clientNameController = TextEditingController();
  final _profileService = CaregiverProfileService();
  final _authService = AuthService();
  
  String? _selectedRole;
  String? _selectedAgeRange;
  String _selectedLanguage = 'nl';
  bool _isLoading = false;
  String? _errorMessage;
  String? _caregiverName;

  @override
  void initState() {
    super.initState();
    _loadCaregiverName();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    super.dispose();
  }

  /// Load caregiver name from Firebase Auth display name or email
  void _loadCaregiverName() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _caregiverName = user.displayName ?? user.email?.split('@').first ?? 'Caregiver';
      });
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
        name: _caregiverName ?? 'Caregiver',
        role: _selectedRole!,
        clientName: _clientNameController.text.trim().isEmpty 
            ? null 
            : _clientNameController.text.trim(),
        ageRange: _selectedAgeRange,
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
        name: _caregiverName ?? 'Caregiver',
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
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  items: [
                    DropdownMenuItem(
                      value: 'Parent',
                      child: Text(
                        localizations.roleParent,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Teacher',
                      child: Text(
                        localizations.roleTeacher,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Therapist',
                      child: Text(
                        localizations.roleTherapist,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
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
                
                // Client Name field (optional)
                TextFormField(
                  controller: _clientNameController,
                  decoration: InputDecoration(
                    labelText: localizations.clientName,
                    hintText: localizations.enterClientName,
                    prefixIcon: const Icon(Icons.child_care_outlined),
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
                
                // Client Age Range dropdown (optional)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: localizations.clientAgeRange,
                    hintText: localizations.selectAgeRange,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  dropdownColor: AppTheme.surfaceWhite,
                  menuMaxHeight: 200,
                  items: [
                    DropdownMenuItem(
                      value: '3-5',
                      child: Text(
                        localizations.ageRange3to5,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '6-9',
                      child: Text(
                        localizations.ageRange6to9,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '10-14',
                      child: Text(
                        localizations.ageRange10to14,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '15+',
                      child: Text(
                        localizations.ageRange15plus,
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAgeRange = value;
                    });
                  },
                  value: _selectedAgeRange,
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
                  items: [
                    DropdownMenuItem(
                      value: 'nl',
                      child: const Text(
                        'Nederlands',
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: const Text(
                        'English',
                        style: TextStyle(color: Colors.black, fontSize: 18),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
