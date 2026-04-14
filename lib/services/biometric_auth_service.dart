import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAuthStatus {
  success,
  failed,
  notEnrolled,
  notAvailable,
  lockedOut,
  permanentlyLockedOut,
}

class BiometricAuthResult {
  final BiometricAuthStatus status;
  final String? message;

  const BiometricAuthResult(this.status, {this.message});

  bool get isSuccess => status == BiometricAuthStatus.success;
}

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  Future<BiometricAuthResult> authenticate({required String reason}) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
      return BiometricAuthResult(
        success ? BiometricAuthStatus.success : BiometricAuthStatus.failed,
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return const BiometricAuthResult(
          BiometricAuthStatus.notEnrolled,
          message: 'No biometrics enrolled',
        );
      }
      if (e.code == 'NotAvailable') {
        return const BiometricAuthResult(
          BiometricAuthStatus.notAvailable,
          message: 'Biometrics not available',
        );
      }
      if (e.code == 'LockedOut') {
        return const BiometricAuthResult(
          BiometricAuthStatus.lockedOut,
          message: 'Biometric sensor temporarily locked',
        );
      }
      if (e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthResult(
          BiometricAuthStatus.permanentlyLockedOut,
          message: 'Biometric sensor permanently locked',
        );
      }
      return BiometricAuthResult(
        BiometricAuthStatus.failed,
        message: e.message,
      );
    } catch (_) {
      return const BiometricAuthResult(BiometricAuthStatus.failed);
    }
  }

  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {
      // Ignore stop errors.
    }
  }
}
