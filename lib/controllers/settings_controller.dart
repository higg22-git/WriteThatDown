import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/provider_config.dart';
import '../models/provider_type.dart';
import '../services/storage/app_settings_repository.dart';
import '../services/storage/secure_key_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._settingsRepository, this._secureKeyRepository);

  final AppSettingsRepository _settingsRepository;
  final SecureKeyRepository _secureKeyRepository;

  AppSettings _settings = AppSettings.defaults();
  bool _isInitialized = false;
  bool _isSaving = false;
  String? _error;
  Map<ProviderType, bool> _hasApiKeys = {
    for (final provider in ProviderType.values) provider: false,
  };

  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Map<ProviderType, bool> get hasApiKeys => _hasApiKeys;

  bool get hasAnyConfiguredProvider =>
      _hasApiKeys.values.any((hasKey) => hasKey);

  Future<void> initialize() async {
    _settings = await _settingsRepository.load();
    await _refreshKeyPresence();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveAll({
    required ProviderType selectedChatProvider,
    required ProviderType selectedExtractionProvider,
    required Map<ProviderType, ProviderConfig> providerConfigs,
    required Map<ProviderType, String> pendingApiKeys,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _settings = AppSettings(
        selectedChatProvider: selectedChatProvider,
        selectedExtractionProvider: selectedExtractionProvider,
        providerConfigs: providerConfigs,
      );

      await _settingsRepository.save(_settings);

      for (final entry in pendingApiKeys.entries) {
        final value = entry.value.trim();
        if (value.isNotEmpty) {
          await _secureKeyRepository.writeKey(entry.key, value);
        }
      }

      await _refreshKeyPresence();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _refreshKeyPresence() async {
    final updated = <ProviderType, bool>{};
    for (final provider in ProviderType.values) {
      updated[provider] = await _secureKeyRepository.hasKey(provider);
    }
    _hasApiKeys = updated;
  }
}
