class ExtractionResult {
  const ExtractionResult({
    required this.title,
    required this.summary,
    required this.tags,
    required this.seedPrompt,
    required this.sourceExcerpt,
  });

  final String title;
  final String summary;
  final List<String> tags;
  final String seedPrompt;
  final String sourceExcerpt;

  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    return ExtractionResult(
      title: json['title'] as String? ?? 'Untitled idea',
      summary: json['summary'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString().trim())
          .where((tag) => tag.isNotEmpty)
          .take(5)
          .toList(),
      seedPrompt: json['seedPrompt'] as String? ?? '',
      sourceExcerpt: json['sourceExcerpt'] as String? ?? '',
    );
  }
}