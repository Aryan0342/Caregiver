import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/picto_request_service.dart';
import '../services/category_service.dart';
import '../services/language_service.dart';
import '../providers/language_provider.dart';

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
  final _categoryService = CategoryService();

  String? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  static const String _notInListValue = '__not_in_list__';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
      // Debug: print category count
      debugPrint('RequestPictoScreen: Loaded ${categories.length} categories');
    } catch (e, stackTrace) {
      debugPrint('RequestPictoScreen: Error loading categories: $e');
      debugPrint('RequestPictoScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _errorMessage = 'Failed to load categories: $e';
        });
      }
    }
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

    // If "not in list" is selected, description is required
    if (_selectedCategory == _notInListValue) {
      if (_descriptionController.text.trim().isEmpty) {
        final localizations = LanguageProvider.localizationsOf(context);
        setState(() {
          _errorMessage = localizations.describeCategory;
        });
        return;
      }
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

      // If "not in list" is selected, use description as category
      final categoryToSubmit = _selectedCategory == _notInListValue
          ? _descriptionController.text.trim()
          : _selectedCategory!;

      final descriptionToSubmit = _selectedCategory == _notInListValue
          ? null
          : (_descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim());

      await _requestService.submitRequest(
        keyword: _keywordController.text.trim(),
        category: categoryToSubmit,
        description: descriptionToSubmit,
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
                _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                        ? Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.orange.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No categories available. Please contact admin.',
                                        style: TextStyle(
                                            color: Colors.orange.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black),
                                dropdownColor: AppTheme.surfaceWhite,
                                items: [
                                  DropdownMenuItem(
                                    value: _notInListValue,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.7,
                                      child: Text(
                                        localizations.notInListDescribe,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ],
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
                            ],
                          )
                        : DropdownButtonFormField<String>(
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
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black),
                            dropdownColor: AppTheme.surfaceWhite,
                            menuMaxHeight: 300,
                            isExpanded: true,
                            items: [
                              // Admin-created categories
                              ..._categories.map((category) {
                                final languageService =
                                    LanguageProvider.languageServiceOf(context);
                                final languageCode =
                                    languageService.currentLanguage ==
                                            AppLanguage.dutch
                                        ? 'nl'
                                        : 'en';
                                return DropdownMenuItem(
                                  value: category.id,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: Text(
                                      category.getLocalizedName(languageCode),
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }),
                              // "Not in list" option
                              DropdownMenuItem(
                                value: _notInListValue,
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Text(
                                    localizations.notInListDescribe,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                _errorMessage = null;
                                // Clear description if switching away from "not in list"
                                if (value != _notInListValue) {
                                  _descriptionController.clear();
                                }
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

                // Description field (required if "not in list" is selected, otherwise optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: _selectedCategory == _notInListValue
                        ? '${localizations.description} *'
                        : localizations.description,
                    hintText: _selectedCategory == _notInListValue
                        ? localizations.describeCategory
                        : localizations.enterDescription,
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
                  validator: _selectedCategory == _notInListValue
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localizations.describeCategory;
                          }
                          return null;
                        }
                      : null,
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
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                      border: Border.all(
                          color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppTheme.accentGreen),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
