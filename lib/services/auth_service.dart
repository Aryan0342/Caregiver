import 'package:firebase_auth/firebase_auth.dart';

/// Service class for handling Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  /// Returns a result object with success status and error message
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        errorMessage: 'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
      );
    }
  }

  /// Create a new caregiver account with email and password.
  /// 
  /// This method is ONLY for caregivers. Clients must NEVER authenticate.
  /// 
  /// Returns a result object with success status, Firebase UID (on success), and error message.
  /// 
  /// [email] - Caregiver's email address
  /// [password] - Caregiver's password (minimum 6 characters)
  /// 
  /// Returns AuthResult with:
  /// - success: true if account created successfully
  /// - uid: Firebase UID of the created user (only if success is true)
  /// - errorMessage: Friendly error message if creation failed
  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Return success with Firebase UID
      return AuthResult(
        success: true,
        uid: userCredential.user?.uid,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        errorMessage: 'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
      );
    }
  }

  /// Send password reset email to caregiver.
  /// 
  /// This method sends a password reset email using Firebase Auth.
  /// Only caregivers can use this feature.
  /// 
  /// [email] - Caregiver's email address
  /// 
  /// Returns AuthResult with:
  /// - success: true if email sent successfully
  /// - errorMessage: Friendly error message if sending failed
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        errorMessage: 'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
      );
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Convert Firebase error codes to friendly, caregiver-friendly error messages.
  /// 
  /// All error messages are in Dutch and avoid technical jargon.
  /// Designed for caregivers with minimal technical knowledge.
  String _getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Er is geen account gevonden met dit e-mailadres. Controleer uw e-mailadres en probeer het opnieuw.';
      case 'wrong-password':
        return 'Het ingevoerde wachtwoord is onjuist. Controleer uw wachtwoord en probeer het opnieuw.';
      case 'invalid-email':
        return 'Het ingevoerde e-mailadres is ongeldig. Voer een geldig e-mailadres in (bijvoorbeeld: naam@voorbeeld.nl).';
      case 'user-disabled':
        return 'Dit account is tijdelijk uitgeschakeld. Neem contact op met de beheerder voor hulp.';
      case 'email-already-in-use':
        return 'Er bestaat al een account met dit e-mailadres. Gebruik een ander e-mailadres of log in met uw bestaande account.';
      case 'weak-password':
        return 'Het wachtwoord is te zwak. Gebruik minimaal 6 tekens. Kies een sterk wachtwoord voor uw veiligheid.';
      case 'operation-not-allowed':
        return 'Deze bewerking is momenteel niet toegestaan. Neem contact op met de beheerder voor hulp.';
      case 'too-many-requests':
        return 'Te veel pogingen gedaan. Wacht even en probeer het later opnieuw.';
      case 'network-request-failed':
        return 'Geen internetverbinding. Controleer uw internetverbinding en probeer het opnieuw.';
      case 'invalid-credential':
        return 'De ingevoerde gegevens zijn onjuist. Controleer uw e-mailadres en wachtwoord.';
      case 'invalid-verification-code':
        return 'De verificatiecode is ongeldig of verlopen. Vraag een nieuwe code aan.';
      case 'invalid-verification-id':
        return 'De verificatie is verlopen. Probeer het opnieuw.';
      default:
        return 'Er is een fout opgetreden. Probeer het opnieuw. Als het probleem aanhoudt, neem contact op met de beheerder.';
    }
  }

}

/// Result class for authentication operations.
/// 
/// Contains:
/// - success: Whether the operation succeeded
/// - uid: Firebase UID of the authenticated user (only on successful signup/login)
/// - errorMessage: Friendly error message if operation failed
class AuthResult {
  final bool success;
  final String? uid;
  final String? errorMessage;

  const AuthResult({
    required this.success,
    this.uid,
    this.errorMessage,
  });
}
