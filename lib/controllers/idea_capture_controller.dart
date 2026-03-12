import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/idea_tile.dart';
import '../services/llm/llm_gateway.dart';
import '../services/storage/idea_repository.dart';
import 'ideas_controller.dart';
import 'settings_controller.dart';

class IdeaCaptureController extends ChangeNotifier {
  IdeaCaptureController(
    this._llmGateway,
    this._ideaRepository,
    this._settingsController,
    this._ideasController,
  );

  final LlmGateway _llmGateway;
  final IdeaRepository _ideaRepository;
  final SettingsController _settingsController;
  final IdeasController _ideasController;
  final Uuid _uuid = const Uuid();

  bool _isSaving = false;
  String? _error;

  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<IdeaTile?> saveIdea({
    required List<ChatMessage> conversation,
    required String triggerType,
  }) async {
    if (_isSaving || conversation.isEmpty) {
      return null;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final execution = await _llmGateway.extractIdea(
        settings: _settingsController.settings,
        conversation: conversation,
      );

      final result = execution.result;
      final idea = IdeaTile(
        id: _uuid.v4(),
        title: result.title.trim().isEmpty ? 'Untitled idea' : result.title.trim(),
        summary: result.summary.trim(),
        tags: result.tags,
        triggerType: triggerType,
        providerId: execution.providerType.name,
        modelId: execution.model,
        seedPrompt: result.seedPrompt.trim(),
        sourceExcerpt: result.sourceExcerpt.trim(),
        capturedAt: DateTime.now(),
      );

      await _ideaRepository.saveIdea(idea);
      await _ideasController.addIdea(idea);
      return idea;
    } catch (error) {
      _error = error.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
