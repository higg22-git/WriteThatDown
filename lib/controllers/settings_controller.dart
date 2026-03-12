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

  /// Returns true if at least one enabled provider has a verified API key.
  bool get hasAnyVerifiedProvider =>
      _settings.providerConfigs.values.any((c) => c.isEnabled && c.isVerified);

  Future<void> initialize() async {
    _settings = await _settingsRepository.load();
    await _refreshKeyPresence();

    // Backward compatibility: treat any already-stored API key as pre-verified
    // so existing users are not suddenly blocked after an app update.
    // New keys added through onboarding or settings go through the live
    // verification flow before they are saved with isVerified = true.
    var needsSave = false;
    final updatedConfigs = Map<ProviderType, ProviderConfig>.from(_settings.providerConfigs);
    for (final provider in ProviderType.values) {
      if (_hasApiKeys[provider] == true &&
          !(updatedConfigs[provider]?.isVerified ?? false)) {
        updatedConfigs[provider] =
            (updatedConfigs[provider] ?? ProviderConfig.defaults(provider))
                .copyWith(isVerified: true);
        needsSave = true;
      }
    }
    if (needsSave) {
      _settings = _settings.copyWith(providerConfigs: updatedConfigs);
      await _settingsRepository.save(_settings);
    }

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
