import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    super.key,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = isUser
        ? const Color(0xFF174C4F)
        : Theme.of(context).colorScheme.surface;
    final textColor = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUser ? const Color(0xFF174C4F) : const Color(0xFFD7C7A9),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat.jm().format(message.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.78),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
