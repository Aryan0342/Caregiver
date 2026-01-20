import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguageProvider extends InheritedWidget {
  final LanguageService languageService;
  final AppLocalizations localizations;

  const LanguageProvider({
    super.key,
    required this.languageService,
    required this.localizations,
    required super.child,
  });

  static LanguageProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LanguageProvider>();
  }

  static AppLocalizations localizationsOf(BuildContext context) {
    final provider = of(context);
    return provider?.localizations ?? AppLocalizations(AppLanguage.dutch);
  }

  static LanguageService languageServiceOf(BuildContext context) {
    final provider = of(context);
    return provider?.languageService ?? LanguageService();
  }

  @override
  bool updateShouldNotify(LanguageProvider oldWidget) {
    return languageService.currentLanguage != oldWidget.languageService.currentLanguage;
  }
}
