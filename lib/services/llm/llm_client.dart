import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../models/chat_message.dart';
import '../../models/extraction_result.dart';
import '../../models/provider_type.dart';

abstract class LlmClient {
  Future<String> completeChat({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    String? seedPrompt,
  });

  Future<ExtractionResult> extractIdea({
    required String apiKey,
    required String model,
    required List<ChatMessage> conversation,
  });

  /// Performs a lightweight check to confirm [apiKey] is accepted by the
  /// provider.  Throws a [DioException] with status 401 or 403 when the key is
  /// rejected; throws any other [DioException] for network/server errors.
  Future<void> validateApiKey(String apiKey);
}

abstract class BaseLlmClient implements LlmClient {
  BaseLlmClient(this.dio);

  final Dio dio;
  final Uuid _uuid = const Uuid();

  Future<String> rawComplete({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<ChatMessage> messages,
    required double temperature,
  });

  @override
  Future<String> completeChat({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    String? seedPrompt,
  }) {
    return rawComplete(
      apiKey: apiKey,
      model: model,
      systemPrompt: LlmPromptBuilder.chatSystemPrompt(seedPrompt: seedPrompt),
      messages: messages,
      temperature: 0.7,
    );
  }

  @override
  Future<ExtractionResult> extractIdea({
    required String apiKey,
    required String model,
    required List<ChatMessage> conversation,
  }) async {
    final transcriptPrompt = LlmPromptBuilder.extractionUserPrompt(conversation);
    final response = await rawComplete(
      apiKey: apiKey,
      model: model,
      systemPrompt: LlmPromptBuilder.extractionSystemPrompt,
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.user,
          content: transcriptPrompt,
          createdAt: DateTime.now(),
        ),
      ],
      temperature: 0.2,
    );

    final jsonMap = JsonObjectParser.parse(response);
    return ExtractionResult.fromJson(jsonMap);
  }
}

class LlmPromptBuilder {
  static String chatSystemPrompt({String? seedPrompt}) {
    final buffer = StringBuffer()
      ..writeln('You are a focused mobile conversation assistant for exploring and sharpening user ideas.')
      ..writeln('Keep answers practical, concise, and useful in a voice-first interface.')
      ..writeln('Prefer concrete suggestions over long explanations.');

    if (seedPrompt != null && seedPrompt.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Current topic context:')
        ..writeln(seedPrompt.trim());
    }

    return buffer.toString().trim();
  }

  static const String extractionSystemPrompt = '''
You extract the user's most recent concrete idea from a conversation.
Return JSON only. Do not wrap the JSON in markdown.
Focus on the latest user-originated idea, using nearby assistant messages only to clarify it.
Use plain language.
Output this exact shape:
{
  "title": "Short plain title",
  "summary": "One short paragraph",
  "tags": ["tag-one", "tag-two"],
  "seedPrompt": "Compact context used to restart a future conversation about the idea.",
  "sourceExcerpt": "Brief quote or paraphrase of the key source text."
}
Keep tags to 2-5 items.
''';

  static String extractionUserPrompt(List<ChatMessage> conversation) {
    final relevant = conversation.takeLast(12).map((message) {
      final role = switch (message.role) {
        ChatRole.user => 'USER',
        ChatRole.assistant => 'ASSISTANT',
        ChatRole.system => 'SYSTEM',
      };
      return '$role: ${message.content.trim()}';
    }).join('\n');

    return 'Conversation transcript:\n$relevant';
  }
}

class JsonObjectParser {
  static Map<String, dynamic> parse(String raw) {
    final trimmed = raw.trim();
    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        throw const FormatException('Provider did not return valid JSON.');
      }
      final candidate = trimmed.substring(start, end + 1);
      return jsonDecode(candidate) as Map<String, dynamic>;
    }
  }
}

class LlmClientFactory {
  LlmClientFactory(this._dio);

  final Dio _dio;

  LlmClient create(ProviderType type) {
    switch (type) {
      case ProviderType.openai:
        return OpenAiClient(_dio);
      case ProviderType.anthropic:
        return AnthropicClient(_dio);
      case ProviderType.google:
        return GoogleAiStudioClient(_dio);
      case ProviderType.groq:
        return GroqClient(_dio);
    }
  }
}

class OpenAiClient extends BaseLlmClient {
  OpenAiClient(super.dio);

  @override
  Future<void> validateApiKey(String apiKey) async {
    await dio.get<dynamic>(
      'https://api.openai.com/v1/models',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
    );
  }

  @override
  Future<String> rawComplete({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<ChatMessage> messages,
    required double temperature,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {'Authorization': 'Bearer $apiKey'},
      ),
      data: {
        'model': model,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages.map(
            (message) => {
              'role': message.role.name,
              'content': message.content,
            },
          ),
        ],
      },
    );

    return (((response.data?['choices'] as List<dynamic>?)?.firstOrNull
                    as Map<String, dynamic>?)?['message']
                as Map<String, dynamic>?)?['content']
            as String? ??
        '';
  }
}

class GroqClient extends BaseLlmClient {
  GroqClient(super.dio);

  @override
  Future<void> validateApiKey(String apiKey) async {
    await dio.get<dynamic>(
      'https://api.groq.com/openai/v1/models',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
    );
  }

  @override
  Future<String> rawComplete({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<ChatMessage> messages,
    required double temperature,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.groq.com/openai/v1/chat/completions',
      options: Options(
        headers: {'Authorization': 'Bearer $apiKey'},
      ),
      data: {
        'model': model,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages.map(
            (message) => {
              'role': message.role.name,
              'content': message.content,
            },
          ),
        ],
      },
    );

    return (((response.data?['choices'] as List<dynamic>?)?.firstOrNull
                    as Map<String, dynamic>?)?['message']
                as Map<String, dynamic>?)?['content']
            as String? ??
        '';
  }
}

class AnthropicClient extends BaseLlmClient {
  AnthropicClient(super.dio);

  @override
  Future<void> validateApiKey(String apiKey) async {
    // Anthropic has no free metadata endpoint; use a minimal 1-token completion
    // as a lightweight auth probe.
    await dio.post<dynamic>(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ),
      data: {
        'model': ProviderType.anthropic.defaultChatModel,
        'max_tokens': 1,
        'messages': [
          {'role': 'user', 'content': '1'},
        ],
      },
    );
  }

  @override
  Future<String> rawComplete({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<ChatMessage> messages,
    required double temperature,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ),
      data: {
        'model': model,
        'system': systemPrompt,
        'temperature': temperature,
        'max_tokens': 1024,
        'messages': messages
            .where((message) => message.role != ChatRole.system)
            .map(
              (message) => {
                'role': message.role == ChatRole.assistant ? 'assistant' : 'user',
                'content': message.content,
              },
            )
            .toList(),
      },
    );

    final content = response.data?['content'] as List<dynamic>? ?? const [];
    if (content.isEmpty) {
      return '';
    }

    final first = content.first as Map<String, dynamic>;
    return first['text'] as String? ?? '';
  }
}

class GoogleAiStudioClient extends BaseLlmClient {
  GoogleAiStudioClient(super.dio);

  @override
  Future<void> validateApiKey(String apiKey) async {
    await dio.get<dynamic>(
      'https://generativelanguage.googleapis.com/v1beta/models',
      queryParameters: {'key': apiKey},
    );
  }

  @override
  Future<String> rawComplete({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<ChatMessage> messages,
    required double temperature,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'generationConfig': {
          'temperature': temperature,
        },
        'contents': messages
            .where((message) => message.role != ChatRole.system)
            .map(
              (message) => {
                'role': message.role == ChatRole.assistant ? 'model' : 'user',
                'parts': [
                  {'text': message.content},
                ],
              },
            )
            .toList(),
      },
    );

    final candidates = response.data?['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) {
      return '';
    }

    final first = candidates.first as Map<String, dynamic>;
    final content = first['content'] as Map<String, dynamic>? ?? const {};
    final parts = content['parts'] as List<dynamic>? ?? const [];
    if (parts.isEmpty) {
      return '';
    }

    return (parts.first as Map<String, dynamic>)['text'] as String? ?? '';
  }
}

extension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) {
      return List<T>.from(this);
    }
    return sublist(length - count);
  }
}

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
