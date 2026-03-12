import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/idea_tile.dart';
import '../../providers.dart';
import 'chat_screen.dart';
import 'ideas_screen.dart';
import 'settings_screen.dart';
import 'voice_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final PageController _pageController;
  int _currentIndex = 1;

  static const _titles = ['Ideas', 'Write That Down', 'Voice'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SettingsScreen(),
    );
  }

  Future<void> _moveToPage(int index) {
    return _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _startVoiceFromIdea(IdeaTile idea) {
    ref.read(chatControllerProvider).seedConversation(idea);
    _moveToPage(2);
  }

  @override
  Widget build(BuildContext context) {
    final chatController = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex != 0 &&
              (chatController.messages.isNotEmpty || chatController.seedPrompt != null))
            TextButton(
              onPressed: () => ref.read(chatControllerProvider).clearConversation(),
              child: const Text('New'),
            ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4E8CC), Color(0xFFF7F2E6)],
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            IdeasScreen(onStartVoiceFromIdea: _startVoiceFromIdea),
            ChatScreen(onOpenVoice: () => _moveToPage(2), onOpenSettings: _openSettings),
            const VoiceScreen(),
          ],
        ),
      ),
    );
  }
}
