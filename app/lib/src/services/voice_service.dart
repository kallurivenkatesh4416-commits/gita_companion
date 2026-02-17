import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  static const double _calmSpeechRate = 0.4;
  static const double _calmPitch = 0.9;
  static const double _calmVolume = 0.85;

  bool _speechInitialized = false;
  bool _listening = false;
  bool _speaking = false;

  bool get isListening => _listening;
  bool get isSpeaking => _speaking;

  Future<bool> initialize() async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize();
    }
    await _tts.awaitSpeakCompletion(true);
    return _speechInitialized;
  }

  Future<bool> startListening({
    required String localeId,
    required void Function(String text) onResult,
    void Function()? onListeningStopped,
  }) async {
    final ready = await initialize();
    if (!ready || _listening) {
      return ready;
    }

    _listening = true;
    await _speech.listen(
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _listening = false;
          onListeningStopped?.call();
        }
      },
    );
    return true;
  }

  Future<void> stopListening({void Function()? onListeningStopped}) async {
    if (!_listening) {
      return;
    }
    await _speech.stop();
    _listening = false;
    onListeningStopped?.call();
  }

  Future<void> speak({
    required String text,
    required String localeId,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }
    await _tts.stop();
    _speaking = true;
    await _tts.setLanguage(localeId);
    await _tts.setSpeechRate(_calmSpeechRate);
    await _tts.setPitch(_calmPitch);
    await _tts.setVolume(_calmVolume);
    try {
      await _tts.speak(text);
    } finally {
      _speaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _speaking = false;
  }

  Future<void> dispose() async {
    await _speech.stop();
    await _tts.stop();
  }
}
