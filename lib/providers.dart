import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/chat_controller.dart';
import 'controllers/idea_capture_controller.dart';
import 'controllers/ideas_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/voice_controller.dart';
import 'services/llm/llm_client.dart';
import 'services/llm/llm_gateway.dart';
import 'services/speech/speech_service.dart';
import 'services/speech/tts_service.dart';
import 'services/storage/app_settings_repository.dart';
import 'services/storage/idea_repository.dart';
import 'services/storage/secure_key_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository();
});

final secureKeyRepositoryProvider = Provider<SecureKeyRepository>((ref) {
  return SecureKeyRepository();
});

final ideaRepositoryProvider = Provider<IdeaRepository>((ref) {
  return IdeaRepository();
});

final llmClientFactoryProvider = Provider<LlmClientFactory>((ref) {
  return LlmClientFactory(ref.read(dioProvider));
});

final llmGatewayProvider = Provider<LlmGateway>((ref) {
  return LlmGateway(
    ref.read(secureKeyRepositoryProvider),
    ref.read(llmClientFactoryProvider),
  );
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

final settingsControllerProvider = ChangeNotifierProvider<SettingsController>((ref) {
  return SettingsController(
    ref.read(appSettingsRepositoryProvider),
    ref.read(secureKeyRepositoryProvider),
  );
});

final ideasControllerProvider = ChangeNotifierProvider<IdeasController>((ref) {
  return IdeasController(ref.read(ideaRepositoryProvider));
});

final chatControllerProvider = ChangeNotifierProvider<ChatController>((ref) {
  return ChatController(
    ref.read(llmGatewayProvider),
    ref.read(settingsControllerProvider),
  );
});

final ideaCaptureControllerProvider = ChangeNotifierProvider<IdeaCaptureController>((ref) {
  return IdeaCaptureController(
    ref.read(llmGatewayProvider),
    ref.read(ideaRepositoryProvider),
    ref.read(settingsControllerProvider),
    ref.read(ideasControllerProvider),
  );
});

final voiceControllerProvider = ChangeNotifierProvider<VoiceController>((ref) {
  return VoiceController(
    ref.read(speechServiceProvider),
    ref.read(ttsServiceProvider),
    ref.read(chatControllerProvider),
    ref.read(ideaCaptureControllerProvider),
  );
});
