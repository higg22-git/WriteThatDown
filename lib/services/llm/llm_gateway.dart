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

  /// Validates the selected chat provider's API key by making a lightweight
  /// network call.  Returns `null` on success, or a human-readable error
  /// message when the key is missing or rejected (HTTP 401 / 403).
  ///
  /// Non-authentication network errors are silently ignored so that a
  /// temporary connectivity issue does not block the user from opening chat.
  Future<String?> validateChatApiKey(AppSettings settings) async {
    final provider = settings.selectedChatProvider;
    final config = settings.configFor(provider);
    if (!config.isEnabled) {
      return '${provider.displayName} is disabled in settings. '
          'Please enable it or choose a different provider.';
    }
    try {
      final apiKey = await _requireApiKey(provider);
      final client = _clientFactory.create(provider);
      await client.validateApiKey(apiKey);
      return null;
    } on StateError catch (e) {
      return '${e.message} Open Settings to add one.';
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return 'The ${provider.displayName} API key was rejected (HTTP $status). '
            'Please check your key in Settings.';
      }
      // Network / server outage – don't block chat.
      return null;
    }
  }

  /// Tests an API key for the given provider with a real network call.
  /// Returns `null` on success, or a descriptive error message on failure.
  /// Use this during setup to verify connectivity before saving the key.
  Future<String?> testConnection(ProviderType provider, String apiKey) async {
    try {
      final client = _clientFactory.create(provider);
      await client.validateApiKey(apiKey);
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return 'The ${provider.displayName} API key was rejected (HTTP $status). '
            'Double-check you copied the full key correctly.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Connection to ${provider.displayName} timed out. '
            'Check your internet connection and try again.';
      }
      final detail = e.response?.data?.toString() ?? e.message ?? 'network error';
      return 'Could not reach ${provider.displayName}: $detail. '
          'Check your internet connection and try again.';
    } catch (_) {
      return 'An unexpected error occurred while verifying ${provider.displayName}. '
          'Please try again.';
    }
  }
}
