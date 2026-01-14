import 'package:flutter/material.dart';
import '../services/language_service.dart';

class AppLocalizations {
  final AppLanguage _language;

  AppLocalizations(AppLanguage language) : _language = language;

  // App name
  String get appName => _language == AppLanguage.dutch ? 'Dag in beeld' : 'Day in view';
  String get appSubtitle => _language == AppLanguage.dutch ? 'pictoreeksen' : 'pictogram sequences';

  // Common
  String get close => _language == AppLanguage.dutch ? 'Sluiten' : 'Close';
  String get save => _language == AppLanguage.dutch ? 'Opslaan' : 'Save';
  String get cancel => _language == AppLanguage.dutch ? 'Annuleren' : 'Cancel';
  String get edit => _language == AppLanguage.dutch ? 'Bewerken' : 'Edit';
  String get delete => _language == AppLanguage.dutch ? 'Verwijderen' : 'Delete';
  String get done => _language == AppLanguage.dutch ? 'Klaar' : 'Done';
  String get next => _language == AppLanguage.dutch ? 'Volgende' : 'Next';
  String get previous => _language == AppLanguage.dutch ? 'Vorige' : 'Previous';
  String get back => _language == AppLanguage.dutch ? 'Terug' : 'Back';
  String get loading => _language == AppLanguage.dutch ? 'Laden...' : 'Loading...';
  String get error => _language == AppLanguage.dutch ? 'Fout' : 'Error';

  // Login screen
  String get login => _language == AppLanguage.dutch ? 'Inloggen' : 'Login';
  String get emailAddress => _language == AppLanguage.dutch ? 'E-mailadres' : 'Email address';
  String get enterEmail => _language == AppLanguage.dutch ? 'Voer uw e-mailadres in' : 'Enter your email address';
  String get password => _language == AppLanguage.dutch ? 'Wachtwoord' : 'Password';
  String get enterPassword => _language == AppLanguage.dutch ? 'Voer uw wachtwoord in' : 'Enter your password';
  String get testLogin => _language == AppLanguage.dutch ? 'Test Inloggen' : 'Test Login';
  String get testAccount => _language == AppLanguage.dutch ? 'Test account' : 'Test account';

  // Home screen
  String get createPictogramSeries => _language == AppLanguage.dutch ? 'Pictoreeks Maken' : 'Create Pictogram Series';
  String get togetherStepByStep => _language == AppLanguage.dutch ? 'Samen stap voor stap' : 'Together step by step';
  String get newPictogramSet => _language == AppLanguage.dutch ? 'Nieuwe pictoreeks' : 'New pictogram set';
  String get createNewSet => _language == AppLanguage.dutch ? 'Maak een nieuwe pictogramreeks' : 'Create a new pictogram sequence';
  String get myPictogramSets => _language == AppLanguage.dutch ? 'Mijn pictoreeksen' : 'My pictogram sets';
  String get viewMySets => _language == AppLanguage.dutch ? 'Bekijk uw pictogramreeksen' : 'View your pictogram sequences';
  String get settings => _language == AppLanguage.dutch ? 'Instellingen' : 'Settings';
  String get appSettings => _language == AppLanguage.dutch ? 'App-instellingen en voorkeuren' : 'App settings and preferences';
  String get logout => _language == AppLanguage.dutch ? 'Uitloggen' : 'Logout';

  // Create/Edit set screen
  String get editPictogramSet => _language == AppLanguage.dutch ? 'Pictoreeks bewerken' : 'Edit pictogram set';
  String get giveAName => _language == AppLanguage.dutch ? 'Geef een naam...' : 'Give a name...';
  String get begin => _language == AppLanguage.dutch ? 'Begin' : 'Begin';
  String get enterName => _language == AppLanguage.dutch ? 'Voer een naam in' : 'Enter a name';
  String get selectedPictograms => _language == AppLanguage.dutch ? 'Geselecteerde pictogrammen' : 'Selected pictograms';
  String get addPictograms => _language == AppLanguage.dutch ? 'Toevoegen' : 'Add';
  String get selectAtLeastOne => _language == AppLanguage.dutch ? 'Selecteer minimaal één pictogram' : 'Select at least one pictogram';
  String get setSaved => _language == AppLanguage.dutch ? 'Pictoreeks opgeslagen!' : 'Pictogram set saved!';
  String get setUpdated => _language == AppLanguage.dutch ? 'Pictoreeks bijgewerkt!' : 'Pictogram set updated!';
  String get saveError => _language == AppLanguage.dutch ? 'Fout bij opslaan' : 'Error saving';
  String get step => _language == AppLanguage.dutch ? 'Stap' : 'Step';
  String get of => _language == AppLanguage.dutch ? 'van' : 'of';
  String get reorderInstructions => _language == AppLanguage.dutch 
      ? 'Sleep pictogrammen om de volgorde te wijzigen' 
      : 'Drag pictograms to change the order';

  // My sets screen
  String get noSets => _language == AppLanguage.dutch ? 'Geen pictoreeksen' : 'No pictogram sets';
  String get createFirstSet => _language == AppLanguage.dutch ? 'Maak uw eerste pictoreeks aan' : 'Create your first pictogram set';
  String get errorLoadingSets => _language == AppLanguage.dutch ? 'Fout bij laden van pictoreeksen' : 'Error loading pictogram sets';
  String get steps => _language == AppLanguage.dutch ? 'stappen' : 'steps';
  String get startWithClient => _language == AppLanguage.dutch ? 'Start met cliënt' : 'Start with client';
  String get noPictograms => _language == AppLanguage.dutch ? 'Geen pictogrammen' : 'No pictograms';

  // Client session screen
  String get nextStep => _language == AppLanguage.dutch ? 'Volgende stap' : 'Next step';
  String get allStepsCompleted => _language == AppLanguage.dutch ? 'Alle stappen voltooid!' : 'All steps completed!';
  String get noPictogramsInSet => _language == AppLanguage.dutch ? 'Geen pictogrammen in deze reeks' : 'No pictograms in this set';

  // Settings screen
  String get languageLabel => _language == AppLanguage.dutch ? 'Taal' : 'Language';
  String get offlineModeLabel => _language == AppLanguage.dutch ? 'Offline modus' : 'Offline mode';
  String get aboutApp => _language == AppLanguage.dutch ? 'Over de app' : 'About the app';
  String get privacy => _language == AppLanguage.dutch ? 'Privacy' : 'Privacy';
  String get offlineModeInfo => _language == AppLanguage.dutch 
      ? 'Pictogrammen worden automatisch opgeslagen voor offline gebruik. U kunt de app gebruiken zonder internetverbinding zodra de pictogrammen zijn geladen.'
      : 'Pictograms are automatically saved for offline use. You can use the app without an internet connection once the pictograms are loaded.';
  String get version => _language == AppLanguage.dutch ? 'Versie' : 'Version';
  String get pictogramsFrom => _language == AppLanguage.dutch ? 'Pictogrammen van ARASAAC' : 'Pictograms from ARASAAC';
  String get appDescription => _language == AppLanguage.dutch
      ? 'Een app voor het maken en gebruiken van pictogramreeksen voor dagelijkse routines en zorgcommunicatie.'
      : 'An app for creating and using pictogram sequences for daily routines and healthcare communication.';
  String get privacyPolicy => _language == AppLanguage.dutch ? 'Privacybeleid' : 'Privacy Policy';
  String get dataStorage => _language == AppLanguage.dutch ? 'Gegevensopslag:' : 'Data storage:';
  String get offlineUse => _language == AppLanguage.dutch ? 'Offline gebruik:' : 'Offline use:';
  String get privacyInfo1 => _language == AppLanguage.dutch
      ? 'Uw gegevens worden veilig opgeslagen en alleen gebruikt voor de functionaliteit van de app.'
      : 'Your data is stored securely and only used for the app functionality.';
  String get privacyInfo2 => _language == AppLanguage.dutch
      ? '• Pictogramreeksen worden opgeslagen in Firebase'
      : '• Pictogram sequences are stored in Firebase';
  String get privacyInfo3 => _language == AppLanguage.dutch
      ? '• Alleen u heeft toegang tot uw eigen reeksen'
      : '• Only you have access to your own sequences';
  String get privacyInfo4 => _language == AppLanguage.dutch
      ? '• Geen gegevens worden gedeeld met derden'
      : '• No data is shared with third parties';
  String get privacyInfo5 => _language == AppLanguage.dutch
      ? '• Pictogrammen worden lokaal opgeslagen voor snelle toegang'
      : '• Pictograms are stored locally for quick access';
  String get privacyInfo6 => _language == AppLanguage.dutch
      ? '• U kunt de app offline gebruiken'
      : '• You can use the app offline';
  String get versionInfo => _language == AppLanguage.dutch ? 'Versie en informatie' : 'Version and information';
  String get privacyInfo => _language == AppLanguage.dutch ? 'Privacybeleid en gegevens' : 'Privacy policy and data';
  String get autoSaved => _language == AppLanguage.dutch ? 'Pictogrammen worden automatisch opgeslagen' : 'Pictograms are automatically saved';

  // Pictogram picker
  String get selectPictograms => _language == AppLanguage.dutch ? 'Selecteer pictogrammen' : 'Select pictograms';
  String get searchPictograms => _language == AppLanguage.dutch ? 'Zoek pictogrammen...' : 'Search pictograms...';
  String get categories => _language == AppLanguage.dutch ? 'Categorieën' : 'Categories';
  // ARASAAC Category translations
  String get feeding => _language == AppLanguage.dutch ? 'Voeding' : 'Feeding';
  String get leisure => _language == AppLanguage.dutch ? 'Vrijetijd' : 'Leisure';
  String get place => _language == AppLanguage.dutch ? 'Plaats' : 'Place';
  String get livingBeing => _language == AppLanguage.dutch ? 'Levend wezen' : 'Living being';
  String get education => _language == AppLanguage.dutch ? 'Onderwijs' : 'Education';
  String get time => _language == AppLanguage.dutch ? 'Tijd' : 'Time';
  String get miscellaneous => _language == AppLanguage.dutch ? 'Diversen' : 'Miscellaneous';
  String get movement => _language == AppLanguage.dutch ? 'Beweging' : 'Movement';
  String get religion => _language == AppLanguage.dutch ? 'Religie' : 'Religion';
  String get work => _language == AppLanguage.dutch ? 'Werk' : 'Work';
  String get communication => _language == AppLanguage.dutch ? 'Communicatie' : 'Communication';
  String get document => _language == AppLanguage.dutch ? 'Document' : 'Document';
  String get knowledge => _language == AppLanguage.dutch ? 'Kennis' : 'Knowledge';
  String get object => _language == AppLanguage.dutch ? 'Object' : 'Object';
  String get feelings => _language == AppLanguage.dutch ? 'Gevoelens' : 'Feelings';
  String get health => _language == AppLanguage.dutch ? 'Gezondheid' : 'Health';
  String get body => _language == AppLanguage.dutch ? 'Lichaam' : 'Body';
  
  // Category names - maps to ARASAAC categories
  String getCategoryName(String categoryKey) {
    switch (categoryKey) {
      case 'eten':
        return feeding;
      case 'vrijetijd':
        return leisure;
      case 'plaats':
        return place;
      case 'levendWezen':
        return livingBeing;
      case 'onderwijs':
        return education;
      case 'tijd':
        return time;
      case 'diversen':
        return miscellaneous;
      case 'beweging':
        return movement;
      case 'religie':
        return religion;
      case 'werk':
        return work;
      case 'communicatie':
        return communication;
      case 'document':
        return document;
      case 'kennis':
        return knowledge;
      case 'object':
        return object;
      case 'gevoelens':
        return feelings;
      case 'gezondheid':
        return health;
      case 'lichaam':
        return body;
      default:
        return categoryKey;
    }
  }
  String get selected => _language == AppLanguage.dutch ? 'Geselecteerd' : 'Selected';
  String get pictogramsSelected => _language == AppLanguage.dutch ? 'pictogrammen geselecteerd' : 'pictograms selected';
  String get noPictogramsSelected => _language == AppLanguage.dutch ? 'Geen pictogrammen geselecteerd' : 'No pictograms selected';
  String get choosePictograms => _language == AppLanguage.dutch ? 'Pictogrammen kiezen' : 'Choose pictograms';
  String get name => _language == AppLanguage.dutch ? 'Naam' : 'Name';

  // Error messages
  String get offlineChangesQueued => _language == AppLanguage.dutch
      ? 'Offline: Wijzigingen worden opgeslagen zodra u weer online bent'
      : 'Offline: Changes will be saved once you are back online';
  String get offlineDataUnavailable => _language == AppLanguage.dutch
      ? 'Offline: Gegevens niet beschikbaar'
      : 'Offline: Data unavailable';
  String get offlineModeMessage => _language == AppLanguage.dutch ? 'Offline modus' : 'Offline mode';
  String get offlineMessage => _language == AppLanguage.dutch
      ? 'U bent offline. Toon gecachte gegevens of probeer later opnieuw.'
      : 'You are offline. Showing cached data or try again later.';
  String get indexBuilding => _language == AppLanguage.dutch 
      ? 'Index wordt opgebouwd' 
      : 'Index building';
  String get indexBuildingMessage => _language == AppLanguage.dutch
      ? 'De database-index wordt momenteel opgebouwd. Dit kan enkele minuten duren. U kunt de app blijven gebruiken.'
      : 'The database index is currently being built. This may take a few minutes. You can continue using the app.';

  // Auth errors
  String get notLoggedIn => _language == AppLanguage.dutch ? 'Niet ingelogd' : 'Not logged in';
  String get loginError => _language == AppLanguage.dutch ? 'Fout bij inloggen' : 'Login error';
  String get logoutError => _language == AppLanguage.dutch ? 'Fout bij uitloggen. Probeer het opnieuw.' : 'Error logging out. Please try again.';
  String get errorOccurred => _language == AppLanguage.dutch ? 'Er is een fout opgetreden' : 'An error occurred';
  String get errorCreatingTestAccount => _language == AppLanguage.dutch ? 'Fout bij aanmaken test account' : 'Error creating test account';
  String get errorTestLogin => _language == AppLanguage.dutch ? 'Fout bij inloggen met test account' : 'Error logging in with test account';
  String get successTestLogin => _language == AppLanguage.dutch ? 'Succesvol ingelogd met test account!' : 'Successfully logged in with test account!';
  String get testAccountLabel => _language == AppLanguage.dutch ? 'Test account' : 'Test account';
  
  // Validation messages
  String get enterValidEmail => _language == AppLanguage.dutch ? 'Voer een geldig e-mailadres in' : 'Enter a valid email address';
  String get passwordMinLength => _language == AppLanguage.dutch ? 'Wachtwoord moet minimaal 6 tekens lang zijn' : 'Password must be at least 6 characters long';
}

// Helper to get localizations from context
AppLocalizations getLocalizations(BuildContext context) {
  // This will be provided via InheritedWidget in main.dart
  final languageService = LanguageService();
  return AppLocalizations(languageService.currentLanguage);
}
