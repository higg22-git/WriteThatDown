import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../controllers/voice_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/session_banner.dart';
import 'settings_screen.dart';

class VoiceScreen extends ConsumerWidget {
  const VoiceScreen({super.key});

  Future<void> _saveIdea(BuildContext context, WidgetRef ref) async {
    final conversation = ref.read(chatControllerProvider).messages;
    final idea = await ref.read(ideaCaptureControllerProvider).saveIdea(
          conversation: conversation,
          triggerType: 'manual',
        );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          idea == null
              ? 'Could not save idea: ${ref.read(ideaCaptureControllerProvider).error ?? 'Unknown error'}'
              : 'Saved idea: ${idea.title}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceControllerProvider);
    final chat = ref.watch(chatControllerProvider);
    final ideaCapture = ref.watch(ideaCaptureControllerProvider);
    final settingsController = ref.watch(settingsControllerProvider);
    final recentMessages = chat.messages.reversed.take(4).toList().reversed.toList();

    // Gate: require a verified + enabled AI provider before showing voice mode.
    if (!settingsController.hasAnyVerifiedProvider) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_off_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 20),
                Text(
                  'No AI provider connected',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add and verify an API key in Settings to use voice mode.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => const SettingsScreen(),
                    );
                  },
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
                title: 'Talking about ${chat.activeIdeaTitle}',
                subtitle: chat.seedPrompt ?? '',
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      switch (voice.status) {
                        VoiceStatus.idle => 'Ready',
                        VoiceStatus.unavailable => 'Speech recognition unavailable',
                        VoiceStatus.listening => 'Listening...',
                        VoiceStatus.processing => 'Sending transcript...',
                        VoiceStatus.speaking => 'Speaking reply...',
                        VoiceStatus.error => 'Voice error',
                      },
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: voice.status == VoiceStatus.processing ? null : () => ref.read(voiceControllerProvider).toggleListening(),
                      borderRadius: BorderRadius.circular(90),
                      child: Ink(
                        width: 172,
                        height: 172,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: voice.isListening
                                ? const [Color(0xFFDA6A4E), Color(0xFFC13F27)]
                                : const [Color(0xFF174C4F), Color(0xFF2E6B6C)],
                          ),
                        ),
                        child: Icon(
                          voice.isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      voice.isListening ? 'Tap to stop and send' : 'Tap to start talking',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (voice.liveTranscript.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        voice.liveTranscript,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (voice.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        voice.error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: ideaCapture.isSaving || chat.messages.isEmpty
                            ? null
                            : () => _saveIdea(context, ref),
                        icon: ideaCapture.isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Save Idea Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: recentMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Your current session will appear here as you speak. Swipe left to return to chat without losing context.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentMessages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: recentMessages[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
