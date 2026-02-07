import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
        errorMessage:
            'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
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
      return AuthResult(success: true, uid: userCredential.user?.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        errorMessage:
            'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
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
      final normalizedEmail = email.trim().toLowerCase();

      // Check if email is valid format
      if (normalizedEmail.isEmpty) {
        return const AuthResult(
          success: false,
          errorMessage: 'Voer een geldig e-mailadres in.',
        );
      }

      // Important: Firebase Auth will return success even if the user doesn't exist
      // to prevent email enumeration attacks. However, no email will be sent.
      //
      // Note: The email MUST exist in Firebase Auth for the email to actually be sent.
      // Check Firebase Console > Authentication > Users to verify the email exists.

      debugPrint(
        'Attempting to send password reset email to: $normalizedEmail',
      );
      debugPrint(
        'NOTE: If email is not received, verify the email exists in Firebase Auth.',
      );

      // Send password reset email
      await _auth.sendPasswordResetEmail(
        email: normalizedEmail,
        // ActionCodeSettings can be used to customize the email link
        // For now, use default Firebase handling
      );

      // Log success for debugging
      debugPrint('Password reset email sent successfully to: $normalizedEmail');
      debugPrint('IMPORTANT: If you do not receive the email:');
      debugPrint('1. Check spam/junk folder');
      debugPrint(
        '2. Verify email exists in Firebase Console > Authentication > Users',
      );
      debugPrint('3. Wait 2-3 minutes (email delivery can be delayed)');
      debugPrint(
        '4. Check Firebase Console > Authentication > Templates for email configuration',
      );

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      // Log the error for debugging
      debugPrint(
        'FirebaseAuthException in sendPasswordResetEmail: ${e.code} - ${e.message}',
      );

      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e, stackTrace) {
      // Log unexpected errors with stack trace
      debugPrint('Unexpected error in sendPasswordResetEmail: $e');
      debugPrint('Stack trace: $stackTrace');

      return AuthResult(
        success: false,
        errorMessage:
            'Er is een onverwachte fout opgetreden: $e. Probeer het opnieuw.',
      );
    }
  }

  /// Reset password using email action code.
  ///
  /// This method confirms password reset with a code from email.
  /// [code] - The action code from the password reset email
  /// [newPassword] - The new password to set
  ///
  /// Returns AuthResult with success status and error message
  Future<AuthResult> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        errorMessage:
            'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
      );
    }
  }

  /// Reset password directly after security question verification.
  ///
  /// Uses password reset email flow but handles it automatically.
  /// Since Firebase Auth requires email verification, we send the email
  /// and the user must check their email to complete the reset.
  ///
  /// For a completely email-free solution, implement Firebase Admin SDK on backend.
  ///
  /// [email] - User's email address
  /// [newPassword] - The new password to set
  ///
  /// Returns AuthResult with success status and error message
  Future<AuthResult> resetPasswordAfterSecurityVerification({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email.trim());

      // Note: Firebase Auth client SDK requires email verification for password reset.
      // The user will receive an email with a reset link. When they click it:
      // 1. The app should handle the deep link (if configured)
      // 2. Extract the action code from the URL
      // 3. Use confirmPasswordReset with the extracted code and newPassword
      //
      // For now, we return success but the user needs to check email.
      // In production, implement deep link handling to automate this process.

      // For a completely email-free solution, you need:
      // 1. Firebase Cloud Function with Admin SDK
      // 2. The function should verify security answer and update password
      // 3. Call the function from here instead of sendPasswordResetEmail

      return const AuthResult(
        success: true,
        // Note: Success is returned, but user must complete via email link
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Fout bij resetten van wachtwoord: $e',
      );
    }
  }

  /// Send email verification to the current user.
  ///
  /// This method sends a verification email to the currently logged-in user.
  /// Only works if user is authenticated and email is not already verified.
  ///
  /// Returns AuthResult with:
  /// - success: true if email sent successfully
  /// - errorMessage: Friendly error message if sending failed
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return const AuthResult(
          success: false,
          errorMessage:
              'Geen gebruiker ingelogd. Log in en probeer het opnieuw.',
        );
      }

      if (user.emailVerified) {
        return const AuthResult(
          success: false,
          errorMessage: 'E-mailadres is al geverifieerd.',
        );
      }

      // Send verification email
      await user.sendEmailVerification();

      debugPrint('Email verification sent successfully to: ${user.email}');

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuthException in sendEmailVerification: ${e.code} - ${e.message}',
      );
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint('Unexpected error in sendEmailVerification: $e');
      return AuthResult(
        success: false,
        errorMessage:
            'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
      );
    }
  }

  /// Reload the current user to refresh their data (e.g., emailVerified status).
  ///
  /// This is useful after the user clicks the verification link in their email.
  Future<AuthResult> reloadUser() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return const AuthResult(
          success: false,
          errorMessage: 'Geen gebruiker ingelogd.',
        );
      }

      await user.reload();

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage:
            'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
      );
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete the current user's account after re-authentication.
  /// Caller must delete Firestore data (caregiver profile, pictogram sets) before or after.
  /// [password] - Current password for re-authentication (required by Firebase).
  /// Returns AuthResult with success or errorMessage.
  Future<AuthResult> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthResult(
        success: false,
        errorMessage: 'Geen gebruiker ingelogd.',
      );
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      return const AuthResult(
        success: false,
        errorMessage:
            'E-mailadres niet gevonden. Account kan niet worden verwijderd.',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getFriendlyErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
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

  const AuthResult({required this.success, this.uid, this.errorMessage});
}
