import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'arasaac_service.dart';

enum AppLanguage {
  dutch('nl', 'Nederlands'),
  english('en', 'English');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);
}

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  AppLanguage _currentLanguage = AppLanguage.dutch;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get locale => Locale(_currentLanguage.code);

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      if (languageCode != null) {
        _currentLanguage = AppLanguage.values.firstWhere(
          (lang) => lang.code == languageCode,
          orElse: () => AppLanguage.dutch,
        );
        notifyListeners();
      }
    } catch (e) {
      // Use default language if loading fails
      _currentLanguage = AppLanguage.dutch;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
    } catch (e) {
      // Language change will still work, just won't persist
      debugPrint('Failed to save language preference: $e');
    }

    // Clear all pictogram cache (disk + memory) on language change
    try {
      final arasaacService = ArasaacService();
      await arasaacService.clearAllPictogramCacheFully();
    } catch (e) {
      debugPrint('Failed to clear cache on language change: $e');
    }
  }
}
