import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'app_shell.dart';
import 'onboarding_screen.dart';

class AppBootstrapScreen extends ConsumerStatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  ConsumerState<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends ConsumerState<AppBootstrapScreen> {
  bool _didBootstrap = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBootstrap) return;
    _didBootstrap = true;
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await ref.read(settingsControllerProvider).initialize();
    await ref.read(ideasControllerProvider).loadIdeas();
    await ref.read(voiceControllerProvider).initialize();

    if (!mounted) return;

    final hasKeys =
        ref.read(settingsControllerProvider).hasAnyConfiguredProvider;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => hasKeys ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F0DF), Color(0xFFEAD9B7)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing your voice-first workspace...'),
            ],
          ),
        ),
      ),
    );
  }
}
