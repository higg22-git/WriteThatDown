import 'provider_type.dart';

class ProviderConfig {
  const ProviderConfig({
    required this.type,
    required this.isEnabled,
    required this.chatModel,
    required this.extractionModel,
  });

  final ProviderType type;
  final bool isEnabled;
  final String chatModel;
  final String extractionModel;

  ProviderConfig copyWith({
    bool? isEnabled,
    String? chatModel,
    String? extractionModel,
  }) {
    return ProviderConfig(
      type: type,
      isEnabled: isEnabled ?? this.isEnabled,
      chatModel: chatModel ?? this.chatModel,
      extractionModel: extractionModel ?? this.extractionModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.id,
      'isEnabled': isEnabled,
      'chatModel': chatModel,
      'extractionModel': extractionModel,
    };
  }

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    final type = ProviderTypeX.fromId(json['type'] as String);
    return ProviderConfig(
      type: type,
      isEnabled: json['isEnabled'] as bool? ?? false,
      chatModel: json['chatModel'] as String? ?? type.defaultChatModel,
      extractionModel:
          json['extractionModel'] as String? ?? type.defaultExtractionModel,
    );
  }

  factory ProviderConfig.defaults(ProviderType type) {
    return ProviderConfig(
      type: type,
      isEnabled: type == ProviderType.openai,
      chatModel: type.defaultChatModel,
      extractionModel: type.defaultExtractionModel,
    );
  }
}