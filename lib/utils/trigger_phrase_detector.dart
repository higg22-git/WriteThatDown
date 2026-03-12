class TriggerPhraseMatch {
  const TriggerPhraseMatch({
    required this.shouldCapture,
    required this.cleanedTranscript,
  });

  final bool shouldCapture;
  final String cleanedTranscript;
}

class TriggerPhraseDetector {
  static const List<String> _phrases = [
    'write that down',
    'write that idea down',
  ];

  static TriggerPhraseMatch inspect(String transcript) {
    var cleaned = transcript.trim();
    var shouldCapture = false;
    final lowered = cleaned.toLowerCase();

    for (final phrase in _phrases) {
      if (lowered.contains(phrase)) {
        shouldCapture = true;
        cleaned = cleaned.replaceAll(RegExp(phrase, caseSensitive: false), '');
      }
    }

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return TriggerPhraseMatch(
      shouldCapture: shouldCapture,
      cleanedTranscript: cleaned,
    );
  }
}
