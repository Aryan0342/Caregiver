import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/picto_request_service.dart';
import '../providers/language_provider.dart';
import '../models/pictogram_model.dart';

/// Screen for requesting a new pictogram.
/// 
/// Allows users to request missing pictograms that they need.
class RequestPictoScreen extends StatefulWidget {
  const RequestPictoScreen({super.key});

  @override
  State<RequestPictoScreen> createState() => _RequestPictoScreenState();
}

class _RequestPictoScreenState extends State<RequestPictoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keywordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requestService = PictoRequestService();
  
  String? _selectedCategory;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _keywordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Selecteer een categorie';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Niet ingelogd';
          _isSubmitting = false;
        });
        return;
      }

      await _requestService.submitRequest(
        keyword: _keywordController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        requestedBy: userId,
      );

      if (mounted) {
        setState(() {
          _successMessage = 'Picto aanvraag verzonden!';
          _isSubmitting = false;
        });

        // Clear form
        _keywordController.clear();
        _descriptionController.clear();
        _selectedCategory = null;

        // Show success message and close after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fout bij verzenden: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageProvider.localizationsOf(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(localizations.requestPicto),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  localizations.requestPictoDescription,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.requestPictoSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Keyword field
                TextFormField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    labelText: localizations.keyword,
                    hintText: localizations.enterKeyword,
                    prefixIcon: const Icon(Icons.text_fields),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                  style: const TextStyle(fontSize: 18),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Category dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: localizations.category,
                    hintText: localizations.selectCategory,
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  dropdownColor: AppTheme.surfaceWhite,
                  menuMaxHeight: 300,
                  isExpanded: true,
                  items: PictogramCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category.key,
                      child: Text(
                        localizations.getCategoryName(category.key),
                        style: const TextStyle(color: Colors.black, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _errorMessage = null;
                    });
                  },
                  value: _selectedCategory,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description field (optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: localizations.description,
                    hintText: localizations.enterDescription,
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                  style: const TextStyle(fontSize: 18),
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Success message
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.accentGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Submit button
                SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            localizations.submitRequest,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
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
}
