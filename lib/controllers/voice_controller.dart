import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../services/speech/speech_service.dart';
import '../services/speech/tts_service.dart';
import '../utils/trigger_phrase_detector.dart';
import 'chat_controller.dart';
import 'idea_capture_controller.dart';

enum VoiceStatus {
  idle,
  unavailable,
  listening,
  processing,
  speaking,
  error,
}

class VoiceController extends ChangeNotifier {
  VoiceController(
    this._speechService,
    this._ttsService,
    this._chatController,
    this._ideaCaptureController,
  );

  final SpeechService _speechService;
  final TtsService _ttsService;
  final ChatController _chatController;
  final IdeaCaptureController _ideaCaptureController;

  VoiceStatus _status = VoiceStatus.idle;
  String _liveTranscript = '';
  String? _error;
  bool _isInitialized = false;
  bool _didSubmitCurrentTranscript = false;

  VoiceStatus get status => _status;
  String get liveTranscript => _liveTranscript;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isListening => _status == VoiceStatus.listening;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _ttsService.initialize();
    final available = await _speechService.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
    _isInitialized = true;
    _status = available ? VoiceStatus.idle : VoiceStatus.unavailable;
    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_status == VoiceStatus.unavailable) {
      return;
    }

    if (_speechService.isListening) {
      await stopListening();
      return;
    }

    await _ttsService.stop();
    _liveTranscript = '';
    _error = null;
    _didSubmitCurrentTranscript = false;
    _status = VoiceStatus.listening;
    notifyListeners();

    await _speechService.startListening(onResult: _onResult);
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();

    if (!_didSubmitCurrentTranscript && _liveTranscript.trim().isNotEmpty) {
      _didSubmitCurrentTranscript = true;
      await _submitTranscript(_liveTranscript);
    } else if (_status != VoiceStatus.processing && _status != VoiceStatus.speaking) {
      _status = VoiceStatus.idle;
      notifyListeners();
    }
  }

  Future<void> _submitTranscript(String transcript) async {
    _status = VoiceStatus.processing;
    _error = null;
    notifyListeners();

    try {
      final inspected = TriggerPhraseDetector.inspect(transcript);
      if (inspected.cleanedTranscript.isNotEmpty) {
        final reply = await _chatController.sendUserMessage(inspected.cleanedTranscript);
        if (reply != null && reply.trim().isNotEmpty) {
          _status = VoiceStatus.speaking;
          notifyListeners();
          await _ttsService.speak(reply);
        }
      }

      if (inspected.shouldCapture) {
        await _ideaCaptureController.saveIdea(
          conversation: _chatController.messages,
          triggerType: 'phrase',
        );
      }

      _status = VoiceStatus.idle;
    } catch (error) {
      _error = error.toString();
      _status = VoiceStatus.error;
    }

    notifyListeners();
  }

  void _onResult(SpeechRecognitionResult result) {
    _liveTranscript = result.recognizedWords;
    notifyListeners();

    if (result.finalResult && !_didSubmitCurrentTranscript) {
      _didSubmitCurrentTranscript = true;
      _submitTranscript(result.recognizedWords);
    }
  }

  void _onStatus(String status) {
    if (status == 'notListening' &&
        !_didSubmitCurrentTranscript &&
        _liveTranscript.trim().isNotEmpty) {
      _didSubmitCurrentTranscript = true;
      _submitTranscript(_liveTranscript);
    }
  }

  void _onError(SpeechRecognitionError error) {
    _error = error.errorMsg;
    _status = VoiceStatus.error;
    notifyListeners();
  }
}
