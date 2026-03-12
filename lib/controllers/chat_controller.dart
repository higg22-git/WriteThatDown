import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/idea_tile.dart';
import '../services/llm/llm_gateway.dart';
import 'settings_controller.dart';

class ChatController extends ChangeNotifier {
  ChatController(this._llmGateway, this._settingsController);

  final LlmGateway _llmGateway;
  final SettingsController _settingsController;
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _messages = const [];
  bool _isSending = false;
  String? _error;
  String? _seedPrompt;
  String? _activeIdeaTitle;

  List<ChatMessage> get messages => _messages;
  bool get isSending => _isSending;
  String? get error => _error;
  String? get seedPrompt => _seedPrompt;
  String? get activeIdeaTitle => _activeIdeaTitle;

  Future<String?> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) {
      return null;
    }

    _isSending = true;
    _error = null;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    _messages = [..._messages, userMessage];
    notifyListeners();

    try {
      final reply = await _llmGateway.sendChat(
        settings: _settingsController.settings,
        messages: _messages.takeLast(12),
        seedPrompt: _seedPrompt,
      );

      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.assistant,
        content: reply.trim(),
        createdAt: DateTime.now(),
      );
      _messages = [..._messages, assistantMessage];
      return assistantMessage.content;
    } catch (error) {
      _error = error.toString();
      return null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void seedConversation(IdeaTile idea) {
    _messages = const [];
    _seedPrompt = idea.seedPrompt.isNotEmpty ? idea.seedPrompt : idea.summary;
    _activeIdeaTitle = idea.title;
    _error = null;
    notifyListeners();
  }

  void clearConversation() {
    _messages = const [];
    _seedPrompt = null;
    _activeIdeaTitle = null;
    _error = null;
    notifyListeners();
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
