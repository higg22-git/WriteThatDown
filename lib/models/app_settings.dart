import 'dart:convert';

import 'provider_config.dart';
import 'provider_type.dart';

class AppSettings {
  const AppSettings({
    required this.selectedChatProvider,
    required this.selectedExtractionProvider,
    required this.providerConfigs,
  });

  final ProviderType selectedChatProvider;
  final ProviderType selectedExtractionProvider;
  final Map<ProviderType, ProviderConfig> providerConfigs;

  ProviderConfig configFor(ProviderType type) {
    return providerConfigs[type] ?? ProviderConfig.defaults(type);
  }

  AppSettings copyWith({
    ProviderType? selectedChatProvider,
    ProviderType? selectedExtractionProvider,
    Map<ProviderType, ProviderConfig>? providerConfigs,
  }) {
    return AppSettings(
      selectedChatProvider: selectedChatProvider ?? this.selectedChatProvider,
      selectedExtractionProvider:
          selectedExtractionProvider ?? this.selectedExtractionProvider,
      providerConfigs: providerConfigs ?? this.providerConfigs,
    );
  }

  String toRawJson() {
    return jsonEncode(
      {
        'selectedChatProvider': selectedChatProvider.id,
        'selectedExtractionProvider': selectedExtractionProvider.id,
        'providerConfigs': providerConfigs.map(
          (key, value) => MapEntry(key.id, value.toJson()),
        ),
      },
    );
  }

  factory AppSettings.fromRawJson(String rawJson) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final configMap = decoded['providerConfigs'] as Map<String, dynamic>? ?? {};

    final providerConfigs = <ProviderType, ProviderConfig>{
      for (final type in ProviderType.values)
        type: ProviderConfig.defaults(type),
    };

    for (final entry in configMap.entries) {
      providerConfigs[ProviderTypeX.fromId(entry.key)] = ProviderConfig.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return AppSettings(
      selectedChatProvider: ProviderTypeX.fromId(
        decoded['selectedChatProvider'] as String? ?? ProviderType.openai.id,
      ),
      selectedExtractionProvider: ProviderTypeX.fromId(
        decoded['selectedExtractionProvider'] as String? ?? ProviderType.openai.id,
      ),
      providerConfigs: providerConfigs,
    );
  }

  factory AppSettings.defaults() {
    return AppSettings(
      selectedChatProvider: ProviderType.openai,
      selectedExtractionProvider: ProviderType.openai,
      providerConfigs: {
        for (final type in ProviderType.values) type: ProviderConfig.defaults(type),
      },
    );
  }
}