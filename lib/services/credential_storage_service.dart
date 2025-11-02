import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorageService {
  CredentialStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _identifierKey = 'login_identifier';
  static const String _passwordKey = 'login_password';

  static Future<void> saveCredentials({
    required String identifier,
    required String password,
  }) async {
    await _storage.write(key: _identifierKey, value: identifier);
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<Map<String, String>?> loadCredentials() async {
    final String? identifier = await _storage.read(key: _identifierKey);
    final String? password = await _storage.read(key: _passwordKey);

    if (identifier == null || password == null) {
      return null;
    }

    return {'identifier': identifier, 'password': password};
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _identifierKey);
    await _storage.delete(key: _passwordKey);
  }
}
