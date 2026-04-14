import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricPreferenceService {
  static const String _faceIdEnabledKey = 'face_id_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<bool> isFaceIdEnabled() async {
    try {
      final value = await _storage.read(key: _faceIdEnabledKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setFaceIdEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _faceIdEnabledKey,
        value: enabled ? 'true' : 'false',
      );
    } catch (_) {
      // Ignore storage errors.
    }
  }

  Future<bool> isEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: enabled ? 'true' : 'false',
      );
    } catch (_) {
      // Ignore storage errors.
    }
  }

  Future<String?> getBiometricType() async {
    try {
      return await _storage.read(key: _biometricTypeKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> setBiometricType(String? type) async {
    try {
      if (type == null) {
        await _storage.delete(key: _biometricTypeKey);
      } else {
        await _storage.write(key: _biometricTypeKey, value: type);
      }
    } catch (_) {
      // Ignore storage errors.
    }
  }
}
