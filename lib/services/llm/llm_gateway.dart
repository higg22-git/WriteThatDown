import 'package:dio/dio.dart';

import '../../models/app_settings.dart';
import '../../models/chat_message.dart';
import '../../models/extraction_execution.dart';
import '../../models/provider_type.dart';
import '../storage/secure_key_repository.dart';
import 'llm_client.dart';

class LlmGateway {
  LlmGateway(this._secureKeyRepository, this._clientFactory);

  final SecureKeyRepository _secureKeyRepository;
  final LlmClientFactory _clientFactory;

  Future<String> sendChat({
    required AppSettings settings,
    required List<ChatMessage> messages,
    String? seedPrompt,
  }) async {
    final provider = settings.selectedChatProvider;
    final config = settings.configFor(provider);
    if (!config.isEnabled) {
      throw StateError('${provider.displayName} is disabled in settings.');
    }
    final apiKey = await _requireApiKey(provider);
    final client = _clientFactory.create(provider);
    return client.completeChat(
      apiKey: apiKey,
      model: config.chatModel,
      messages: messages,
      seedPrompt: seedPrompt,
    );
  }

  Future<ExtractionExecution> extractIdea({
    required AppSettings settings,
    required List<ChatMessage> conversation,
  }) async {
    final providerCandidates = <ProviderType>[
      settings.selectedExtractionProvider,
      if (settings.selectedExtractionProvider != settings.selectedChatProvider)
        settings.selectedChatProvider,
    ];

    DioException? lastException;
    StateError? keyError;

    for (final provider in providerCandidates) {
      final config = settings.configFor(provider);
      if (!config.isEnabled) {
        continue;
      }
      try {
        final apiKey = await _requireApiKey(provider);
        final client = _clientFactory.create(provider);
        final result = await client.extractIdea(
          apiKey: apiKey,
          model: config.extractionModel,
          conversation: conversation,
        );
        return ExtractionExecution(
          result: result,
          providerType: provider,
          model: config.extractionModel,
        );
      } on StateError catch (error) {
        keyError = error;
      } on DioException catch (error) {
        lastException = error;
      }
    }

    if (lastException != null) {
      throw lastException!;
    }

    throw keyError ?? StateError('No provider API key is configured.');
  }

  Future<String> _requireApiKey(ProviderType provider) async {
    final apiKey = await _secureKeyRepository.readKey(provider);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw StateError('${provider.displayName} is missing an API key.');
    }
    return apiKey.trim();
  }
}
