import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/idea_tile.dart';

class IdeaTileCard extends StatelessWidget {
  const IdeaTileCard({
    required this.idea,
    required this.onStartVoice,
    super.key,
  });

  final IdeaTile idea;
  final VoidCallback onStartVoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(idea.summary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: idea.tags
                  .map(
                    (tag) => Chip(label: Text(tag)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'Saved ${DateFormat.yMMMd().add_jm().format(idea.capturedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onStartVoice,
              icon: const Icon(Icons.record_voice_over),
              label: const Text('Talk About This Idea'),
            ),
          ],
        ),
      ),
    );
  }
}
