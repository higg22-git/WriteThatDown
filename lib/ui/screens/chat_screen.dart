import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/session_banner.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.onOpenVoice,
    required this.onOpenSettings,
    super.key,
  });

  final VoidCallback onOpenVoice;
  final VoidCallback onOpenSettings;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateApiKey());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _validateApiKey() async {
    if (!mounted) return;
    final settings = ref.read(settingsControllerProvider).settings;
    final error = await ref.read(llmGatewayProvider).validateChatApiKey(settings);
    if (!mounted || error == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('API Key Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onOpenSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      return;
    }

    _textController.clear();
    final reply = await ref.read(chatControllerProvider).sendUserMessage(text);
    if (!mounted) {
      return;
    }

    if (reply == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message failed to send. Check provider settings.')),
      );
    } else {
      Future<void>.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _saveIdea() async {
    final conversation = ref.read(chatControllerProvider).messages;
    final idea = await ref.read(ideaCaptureControllerProvider).saveIdea(
          conversation: conversation,
          triggerType: 'manual',
        );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          idea == null ? 'Could not save idea.' : 'Saved idea: ${idea.title}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider);
    final ideaCapture = ref.watch(ideaCaptureControllerProvider);
    final settingsController = ref.watch(settingsControllerProvider);
    final messages = chat.messages;

    // Gate: require a verified + enabled AI provider before showing chat.
    if (!settingsController.hasAnyVerifiedProvider) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 20),
                Text(
                  'No AI provider connected',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add and verify an API key in Settings to start chatting.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: widget.onOpenSettings,
                  icon: const Icon(Icons.tune),
                  label: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          children: [
            if (chat.activeIdeaTitle != null)
              SessionBanner(
                title: 'Seeded from ${chat.activeIdeaTitle}',
                subtitle: chat.seedPrompt ?? '',
              ),
            if (chat.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  chat.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Start typing, or swipe right into voice mode. Say "write that down" later to turn a conversation into an idea tile.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: messages[index]);
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: ideaCapture.isSaving || messages.isEmpty ? null : _saveIdea,
                    icon: ideaCapture.isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: const Text('Save Idea'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your next message...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: chat.isSending ? null : _sendMessage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: chat.isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
