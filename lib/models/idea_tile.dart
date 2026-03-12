import 'dart:convert';

class IdeaTile {
  const IdeaTile({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    required this.triggerType,
    required this.providerId,
    required this.modelId,
    required this.seedPrompt,
    required this.sourceExcerpt,
    required this.capturedAt,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String triggerType;
  final String providerId;
  final String modelId;
  final String seedPrompt;
  final String sourceExcerpt;
  final DateTime capturedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'tagsJson': jsonEncode(tags),
      'triggerType': triggerType,
      'providerId': providerId,
      'modelId': modelId,
      'seedPrompt': seedPrompt,
      'sourceExcerpt': sourceExcerpt,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory IdeaTile.fromMap(Map<String, dynamic> map) {
    final tagsRaw = map['tagsJson'] as String? ?? '[]';
    return IdeaTile(
      id: map['id'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String,
      tags: (jsonDecode(tagsRaw) as List<dynamic>)
          .map((tag) => tag.toString())
          .toList(),
      triggerType: map['triggerType'] as String,
      providerId: map['providerId'] as String,
      modelId: map['modelId'] as String,
      seedPrompt: map['seedPrompt'] as String? ?? '',
      sourceExcerpt: map['sourceExcerpt'] as String? ?? '',
      capturedAt: DateTime.parse(map['capturedAt'] as String),
    );
  }
}