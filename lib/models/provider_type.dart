enum ProviderType { openai, anthropic, google, groq }

extension ProviderTypeX on ProviderType {
  String get id => name;

  String get displayName {
    switch (this) {
      case ProviderType.openai:
        return 'OpenAI';
      case ProviderType.anthropic:
        return 'Anthropic';
      case ProviderType.google:
        return 'Google AI Studio';
      case ProviderType.groq:
        return 'Groq';
    }
  }

  List<String> get chatModels {
    switch (this) {
      case ProviderType.openai:
        return const ['gpt-4.1-mini', 'gpt-4.1'];
      case ProviderType.anthropic:
        return const ['claude-3-5-haiku-latest', 'claude-3-5-sonnet-latest'];
      case ProviderType.google:
        return const ['gemini-2.0-flash', 'gemini-1.5-pro'];
      case ProviderType.groq:
        return const ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'];
    }
  }

  String get defaultChatModel => chatModels.first;

  String get defaultExtractionModel {
    switch (this) {
      case ProviderType.openai:
        return 'gpt-4.1-mini';
      case ProviderType.anthropic:
        return 'claude-3-5-haiku-latest';
      case ProviderType.google:
        return 'gemini-2.0-flash';
      case ProviderType.groq:
        return 'llama-3.1-8b-instant';
    }
  }

  static ProviderType fromId(String id) {
    return ProviderType.values.firstWhere((value) => value.name == id);
  }
}