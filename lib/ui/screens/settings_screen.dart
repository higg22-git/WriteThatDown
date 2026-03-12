import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/provider_config.dart';
import '../../models/provider_type.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hydrated = false;
  late Map<ProviderType, ProviderConfig> _providerConfigs;
  late Map<ProviderType, String> _pendingApiKeys;
  late ProviderType _selectedChatProvider;
  late ProviderType _selectedExtractionProvider;

  @override
  Widget build(BuildContext context) {
    final settingsController = ref.watch(settingsControllerProvider);
    final settings = settingsController.settings;

    if (!_hydrated && settingsController.isInitialized) {
      _providerConfigs = Map<ProviderType, ProviderConfig>.from(settings.providerConfigs);
      _pendingApiKeys = {
        for (final provider in ProviderType.values) provider: '',
      };
      _selectedChatProvider = settings.selectedChatProvider;
      _selectedExtractionProvider = settings.selectedExtractionProvider;
      _hydrated = true;
    }

    if (!_hydrated) {
      return const SafeArea(
        child: SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provider settings', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'API keys are stored in platform-secure storage. Choose one provider for live chat and one for idea extraction.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<ProviderType>(
                initialValue: _selectedChatProvider,
                decoration: const InputDecoration(labelText: 'Default chat provider'),
                items: ProviderType.values
                    .map(
                      (provider) => DropdownMenuItem(
                        value: provider,
                        child: Text(provider.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedChatProvider = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProviderType>(
                initialValue: _selectedExtractionProvider,
                decoration: const InputDecoration(labelText: 'Default extraction provider'),
                items: ProviderType.values
                    .map(
                      (provider) => DropdownMenuItem(
                        value: provider,
                        child: Text(provider.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedExtractionProvider = value);
                },
              ),
              const SizedBox(height: 16),
              for (final provider in ProviderType.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  provider.displayName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Switch(
                                value: _providerConfigs[provider]?.isEnabled ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    _providerConfigs[provider] = (_providerConfigs[provider] ?? ProviderConfig.defaults(provider))
                                        .copyWith(isEnabled: value);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            settingsController.hasApiKeys[provider] == true
                                ? 'A secure API key is already stored for this provider. Enter a new one only if you want to replace it.'
                                : 'No API key saved yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            obscureText: true,
                            onChanged: (value) => _pendingApiKeys[provider] = value,
                            decoration: InputDecoration(
                              labelText: '${provider.displayName} API key',
                              hintText: settingsController.hasApiKeys[provider] == true ? 'Stored securely' : 'Paste API key',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _providerConfigs[provider]?.chatModel ?? provider.defaultChatModel,
                            decoration: const InputDecoration(labelText: 'Chat model'),
                            items: provider.chatModels
                                .map(
                                  (model) => DropdownMenuItem(
                                    value: model,
                                    child: Text(model),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _providerConfigs[provider] = (_providerConfigs[provider] ?? ProviderConfig.defaults(provider))
                                    .copyWith(chatModel: value);
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _providerConfigs[provider]?.extractionModel ?? provider.defaultExtractionModel,
                            decoration: const InputDecoration(labelText: 'Idea extraction model'),
                            items: provider.chatModels
                                .map(
                                  (model) => DropdownMenuItem(
                                    value: model,
                                    child: Text(model),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _providerConfigs[provider] = (_providerConfigs[provider] ?? ProviderConfig.defaults(provider))
                                    .copyWith(extractionModel: value);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (settingsController.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    settingsController.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: settingsController.isSaving
                      ? null
                      : () async {
                          final configsToSave = Map<ProviderType, ProviderConfig>.from(_providerConfigs);
                          configsToSave[_selectedChatProvider] =
                              (configsToSave[_selectedChatProvider] ?? ProviderConfig.defaults(_selectedChatProvider))
                                  .copyWith(isEnabled: true);
                          configsToSave[_selectedExtractionProvider] =
                              (configsToSave[_selectedExtractionProvider] ?? ProviderConfig.defaults(_selectedExtractionProvider))
                                  .copyWith(isEnabled: true);

                          await ref.read(settingsControllerProvider).saveAll(
                                selectedChatProvider: _selectedChatProvider,
                                selectedExtractionProvider: _selectedExtractionProvider,
                                providerConfigs: configsToSave,
                                pendingApiKeys: _pendingApiKeys,
                              );
                          if (!mounted) {
                            return;
                          }
                          if (ref.read(settingsControllerProvider).error == null) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: settingsController.isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
