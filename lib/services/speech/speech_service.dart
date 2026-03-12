import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();

  bool get isListening => _speechToText.isListening;

  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(SpeechRecognitionError error) onError,
  }) {
    return _speechToText.initialize(onStatus: onStatus, onError: onError);
  }

  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
  }) {
    return _speechToText.listen(
      onResult: onResult,
      partialResults: true,
      listenMode: ListenMode.dictation,
      cancelOnError: true,
    );
  }

  Future<void> stopListening() {
    return _speechToText.stop();
  }
}
