import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/provider_type.dart';

class SecureKeyRepository {
  SecureKeyRepository()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final FlutterSecureStorage _storage;

  String _storageKey(ProviderType type) => 'provider_api_key_${type.id}';

  Future<void> writeKey(ProviderType type, String key) {
    return _storage.write(key: _storageKey(type), value: key);
  }

  Future<String?> readKey(ProviderType type) {
    return _storage.read(key: _storageKey(type));
  }

  Future<bool> hasKey(ProviderType type) async {
    final value = await readKey(type);
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> deleteKey(ProviderType type) {
    return _storage.delete(key: _storageKey(type));
  }
}
