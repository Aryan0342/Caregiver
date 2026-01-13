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
        errorMessage: _getDutchErrorMessage(e.code),
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        errorMessage: 'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
      );
    }
  }

  /// Create a new user account with email and password
  /// Returns a result object with success status and error message
  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getDutchErrorMessage(e.code),
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

  /// Convert Firebase error codes to Dutch error messages
  String _getDutchErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Er is geen gebruiker gevonden met dit e-mailadres.';
      case 'wrong-password':
        return 'Onjuist wachtwoord.';
      case 'invalid-email':
        return 'Ongeldig e-mailadres.';
      case 'user-disabled':
        return 'Dit account is uitgeschakeld.';
      case 'email-already-in-use':
        return 'Er bestaat al een account met dit e-mailadres.';
      case 'weak-password':
        return 'Het wachtwoord is te zwak. Gebruik minimaal 6 tekens.';
      case 'operation-not-allowed':
        return 'Deze bewerking is niet toegestaan.';
      case 'too-many-requests':
        return 'Te veel pogingen. Probeer het later opnieuw.';
      case 'network-request-failed':
        return 'Netwerkfout. Controleer uw internetverbinding.';
      case 'invalid-credential':
        return 'Ongeldige inloggegevens.';
      default:
        return 'Er is een fout opgetreden. Probeer het opnieuw.';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult({
    required this.success,
    this.errorMessage,
  });
}
