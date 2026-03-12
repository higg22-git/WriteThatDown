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
