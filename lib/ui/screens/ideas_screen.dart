import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/idea_tile.dart';
import '../../providers.dart';
import '../widgets/idea_tile_card.dart';

class IdeasScreen extends ConsumerWidget {
  const IdeasScreen({
    required this.onStartVoiceFromIdea,
    super.key,
  });

  final ValueChanged<IdeaTile> onStartVoiceFromIdea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasController = ref.watch(ideasControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF7ED),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD7C7A9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Idea tiles', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Every saved idea stays local on-device. Tap a tile to jump straight into a fresh voice session seeded by its summary.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (ideasController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (ideasController.error != null) {
                    return Center(child: Text(ideasController.error!));
                  }

                  if (ideasController.ideas.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'No ideas yet. Capture one from chat or voice mode and it will land here as a tile.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(ideasControllerProvider).loadIdeas(),
                    child: ListView.builder(
                      itemCount: ideasController.ideas.length,
                      itemBuilder: (context, index) {
                        final idea = ideasController.ideas[index];
                        return IdeaTileCard(
                          idea: idea,
                          onStartVoice: () => onStartVoiceFromIdea(idea),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
