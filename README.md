# Write That Down

Write That Down is a Flutter mobile app for chatting with an LLM, switching into turn-based voice mode, and capturing structured idea tiles locally on-device.

## What is implemented

- Text chat home screen
- Left-swipe ideas screen with local SQLite-backed idea tiles
- Right-swipe voice mode with native speech-to-text and native text-to-speech
- Manual idea saving from chat and voice mode
- Trigger phrase detection for `write that down` and `write that idea down`
- Provider settings for OpenAI, Anthropic, Google AI Studio, and Groq
- Provider API key storage via platform-secure storage
- Separate chat and idea-extraction provider/model selection
- Seeded voice conversations started from saved idea tiles

## Stack

- Flutter
- Riverpod
- Dio
- SQLite via `sqflite`
- `flutter_secure_storage`
- `speech_to_text`
- `flutter_tts`

## Important note

This workspace did not have Flutter installed, so the Dart and Flutter source was scaffolded manually. The native platform folders are not present yet.

To finish bootstrapping the project on a machine with Flutter installed, run:

```bash
flutter create . --platforms=ios,android
flutter pub get
```

After that, reopen the workspace in VS Code or run `flutter analyze` and `flutter run`.

## iOS-first setup

After `flutter create .`, add the required speech permissions to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Write That Down uses the microphone for voice chat and idea capture.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Write That Down uses speech recognition so you can talk to the app.</string>
```

## Android setup

After `flutter create .`, confirm microphone permissions exist in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Provider behavior

- Chat requests use the selected chat provider and model.
- Idea extraction uses the selected extraction provider and model.
- If the extraction provider is unavailable but the chat provider is configured and enabled, extraction falls back to the chat provider.
- Voice mode uses device-native STT/TTS, not provider voice APIs.

## Project structure

- `lib/ui`: screens and widgets
- `lib/controllers`: chat, voice, ideas, and settings orchestration
- `lib/services`: storage, speech, and LLM integrations
- `lib/models`: app contracts and persisted data shapes

## Next steps

1. Install Flutter locally and generate the missing `ios` and `android` folders.
2. Run `flutter pub get`.
3. Validate speech permissions and audio session behavior on a real iPhone.
4. Test each provider with real API keys and adjust model defaults if needed.
5. Add app icons, launch screen assets, and App Store metadata.
