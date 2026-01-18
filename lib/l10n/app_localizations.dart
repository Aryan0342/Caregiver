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
  String get forgotPassword => _language == AppLanguage.dutch ? 'Wachtwoord vergeten?' : 'Forgot password?';
  String get resetPassword => _language == AppLanguage.dutch ? 'Wachtwoord resetten' : 'Reset password';
  String get enterEmailForReset => _language == AppLanguage.dutch ? 'Voer uw e-mailadres in om een wachtwoord reset link te ontvangen' : 'Enter your email address to receive a password reset link';
  String get resetEmailSent => _language == AppLanguage.dutch ? 'Er is een e-mail verzonden met instructies om uw wachtwoord te resetten. Controleer uw inbox.' : 'An email has been sent with instructions to reset your password. Check your inbox.';
  String get resetEmailError => _language == AppLanguage.dutch ? 'Fout bij verzenden van reset e-mail' : 'Error sending reset email';

  // Registration screen
  String get createAccount => _language == AppLanguage.dutch ? 'Account aanmaken' : 'Create account';
  String get fullName => _language == AppLanguage.dutch ? 'Volledige naam' : 'Full name';
  String get enterFullName => _language == AppLanguage.dutch ? 'Voer uw volledige naam in' : 'Enter your full name';
  String get confirmPassword => _language == AppLanguage.dutch ? 'Bevestig wachtwoord' : 'Confirm password';
  String get enterConfirmPassword => _language == AppLanguage.dutch ? 'Voer uw wachtwoord opnieuw in' : 'Enter your password again';
  String get alreadyHaveAccount => _language == AppLanguage.dutch ? 'Al een account? Inloggen' : 'Already have an account? Login';
  String get registrationError => _language == AppLanguage.dutch ? 'Fout bij aanmaken account' : 'Error creating account';
  String get registrationSuccess => _language == AppLanguage.dutch ? 'Account succesvol aangemaakt!' : 'Account created successfully!';
  String get fieldRequired => _language == AppLanguage.dutch ? 'Dit veld is verplicht' : 'This field is required';
  String get invalidEmail => _language == AppLanguage.dutch ? 'Voer een geldig e-mailadres in' : 'Enter a valid email address';
  String get passwordsDoNotMatch => _language == AppLanguage.dutch ? 'Wachtwoorden komen niet overeen' : 'Passwords do not match';
  String get passwordTooShort => _language == AppLanguage.dutch ? 'Wachtwoord moet minimaal 6 tekens lang zijn' : 'Password must be at least 6 characters';

  // Profile setup screen
  String get profileSetup => _language == AppLanguage.dutch ? 'Profiel instellen' : 'Setup profile';
  String get profileSetupDescription => _language == AppLanguage.dutch ? 'Vertel ons iets over uzelf en uw cliënt' : 'Tell us about yourself and your client';
  String get role => _language == AppLanguage.dutch ? 'Rol' : 'Role';
  String get selectRole => _language == AppLanguage.dutch ? 'Selecteer uw rol' : 'Select your role';
  String get roleParent => _language == AppLanguage.dutch ? 'Ouder' : 'Parent';
  String get roleTeacher => _language == AppLanguage.dutch ? 'Leraar' : 'Teacher';
  String get roleTherapist => _language == AppLanguage.dutch ? 'Therapeut' : 'Therapist';
  String get clientName => _language == AppLanguage.dutch ? 'Cliënt naam' : 'Client name';
  String get enterClientName => _language == AppLanguage.dutch ? 'Voer de naam van uw cliënt in (optioneel)' : 'Enter your client\'s name (optional)';
  String get clientAgeRange => _language == AppLanguage.dutch ? 'Leeftijdsgroep cliënt' : 'Client age range';
  String get selectAgeRange => _language == AppLanguage.dutch ? 'Selecteer leeftijdsgroep (optioneel)' : 'Select age range (optional)';
  String get ageRange3to5 => _language == AppLanguage.dutch ? '3-5 jaar' : '3-5 years';
  String get ageRange6to9 => _language == AppLanguage.dutch ? '6-9 jaar' : '6-9 years';
  String get ageRange10to14 => _language == AppLanguage.dutch ? '10-14 jaar' : '10-14 years';
  String get ageRange15plus => _language == AppLanguage.dutch ? '15+ jaar' : '15+ years';
  String get saveProfile => _language == AppLanguage.dutch ? 'Profiel opslaan' : 'Save profile';
  String get profileSaved => _language == AppLanguage.dutch ? 'Profiel opgeslagen!' : 'Profile saved!';
  String get profileSaveError => _language == AppLanguage.dutch ? 'Fout bij opslaan profiel' : 'Error saving profile';
  String get skip => _language == AppLanguage.dutch ? 'Overslaan' : 'Skip';

  // PIN setup/verification
  String get createPin => _language == AppLanguage.dutch ? 'Pincode instellen' : 'Set PIN code';
  String get createPinDescription => _language == AppLanguage.dutch ? 'Kies een pincode van 4 cijfers om uw account te beveiligen' : 'Choose a 4 digit PIN code to secure your account';
  String get confirmPin => _language == AppLanguage.dutch ? 'Bevestig pincode' : 'Confirm PIN';
  String get enterPin => _language == AppLanguage.dutch ? 'Voer pincode in' : 'Enter PIN code';
  String get pinCreated => _language == AppLanguage.dutch ? 'Pincode ingesteld!' : 'PIN code set!';
  String get incorrectPin => _language == AppLanguage.dutch ? 'Onjuiste pincode' : 'Incorrect PIN code';
  String get pinsDoNotMatch => _language == AppLanguage.dutch ? 'Pincodes komen niet overeen' : 'PIN codes do not match';
  String get pinTooShort => _language == AppLanguage.dutch ? 'Pincode moet precies 4 cijfers zijn' : 'PIN must be exactly 4 digits';
  String get pinTooLong => _language == AppLanguage.dutch ? 'Pincode moet precies 4 cijfers zijn' : 'PIN must be exactly 4 digits';
  String get pinRequired => _language == AppLanguage.dutch ? 'Pincode vereist' : 'PIN required';
  String get pinRequiredMessage => _language == AppLanguage.dutch ? 'Voer uw pincode in om door te gaan' : 'Enter your PIN code to continue';
  String get changePin => _language == AppLanguage.dutch ? 'Pincode wijzigen' : 'Change PIN code';
  String get changePinDescription => _language == AppLanguage.dutch ? 'Wijzig uw pincode' : 'Change your PIN code';
  String get currentPin => _language == AppLanguage.dutch ? 'Huidige pincode' : 'Current PIN';
  String get newPin => _language == AppLanguage.dutch ? 'Nieuwe pincode' : 'New PIN';
  String get confirmNewPin => _language == AppLanguage.dutch ? 'Bevestig nieuwe pincode' : 'Confirm new PIN';
  String get pinChanged => _language == AppLanguage.dutch ? 'Pincode gewijzigd!' : 'PIN code changed!';
  String get pinChangeError => _language == AppLanguage.dutch ? 'Fout bij wijzigen pincode' : 'Error changing PIN code';

  // Face ID / Biometric
  String get faceId => _language == AppLanguage.dutch ? 'Face ID' : 'Face ID';
  String get faceIdSetupPrompt => _language == AppLanguage.dutch 
      ? 'Wilt u Face ID inschakelen voor snellere toegang tot de app?'
      : 'Would you like to enable Face ID for faster access to the app?';
  String get enableFaceId => _language == AppLanguage.dutch ? 'Face ID inschakelen' : 'Enable Face ID';
  String get faceIdEnabled => _language == AppLanguage.dutch ? 'Face ID ingeschakeld' : 'Face ID enabled';
  String get faceIdDisabled => _language == AppLanguage.dutch ? 'Face ID uitgeschakeld' : 'Face ID disabled';
  String get biometricAuthFailed => _language == AppLanguage.dutch 
      ? 'Biometrische authenticatie mislukt. Gebruik uw pincode.'
      : 'Biometric authentication failed. Please use your PIN code.';
  String get authenticateWithFaceId => _language == AppLanguage.dutch 
      ? 'Verifieer uw identiteit met Face ID'
      : 'Verify your identity with Face ID';
  String get useFaceId => _language == AppLanguage.dutch ? 'Face ID gebruiken' : 'Use Face ID';
  String get faceIdDescription => _language == AppLanguage.dutch 
      ? 'Gebruik Face ID of vingerafdruk om de app te openen'
      : 'Use Face ID or fingerprint to open the app';

  // Welcome screen
  String get iAmCaregiver => _language == AppLanguage.dutch ? 'Ik ben verzorger' : 'I am a caregiver';
  String get startWithClient => _language == AppLanguage.dutch ? 'Start met cliënt' : 'Start with client';
  String get clientModeDisabledMessage => _language == AppLanguage.dutch 
      ? 'Client modus is beschikbaar nadat een verzorger account is aangemaakt en een pincode is ingesteld.'
      : 'Client mode is available after a caregiver account is created and a PIN code is set.';
  String get enterPinToEnterClientMode => _language == AppLanguage.dutch ? 'Voer uw pincode in om de client modus te starten' : 'Enter your PIN code to start client mode';

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
  String get clearCache => _language == AppLanguage.dutch ? 'Pictogramcache wissen' : 'Clear pictogram cache';
  String get clearCacheDescription => _language == AppLanguage.dutch ? 'Wis alle opgeslagen pictogrammen (schijf en geheugen)' : 'Clear all saved pictograms (disk and memory)';
  String get clearCacheSuccess => _language == AppLanguage.dutch ? 'Cache gewist' : 'Cache cleared';
  String get clearCacheError => _language == AppLanguage.dutch ? 'Fout bij wissen van cache' : 'Error clearing cache';
  String get savedPictogram => _language == AppLanguage.dutch ? 'Opgeslagen pictogram' : 'Saved pictogram';

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
