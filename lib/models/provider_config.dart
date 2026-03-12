import 'provider_type.dart';

class ProviderConfig {
  const ProviderConfig({
    required this.type,
    required this.isEnabled,
    required this.chatModel,
    required this.extractionModel,
    this.isVerified = false,
  });

  final ProviderType type;
  final bool isEnabled;
  final String chatModel;
  final String extractionModel;

  /// Whether the API key was successfully verified with a real network call.
  final bool isVerified;

  ProviderConfig copyWith({
    bool? isEnabled,
    String? chatModel,
    String? extractionModel,
    bool? isVerified,
  }) {
    return ProviderConfig(
      type: type,
      isEnabled: isEnabled ?? this.isEnabled,
      chatModel: chatModel ?? this.chatModel,
      extractionModel: extractionModel ?? this.extractionModel,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.id,
      'isEnabled': isEnabled,
      'chatModel': chatModel,
      'extractionModel': extractionModel,
      'isVerified': isVerified,
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
      isVerified: json['isVerified'] as bool? ?? false,
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