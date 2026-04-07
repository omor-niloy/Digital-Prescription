import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          debugPrint('Microphone permission denied');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Permission check skipped on this platform: $e');
    }

    try {
      if (Platform.isLinux) {
         debugPrint('Speech-to-Text is officially not supported on Linux by the authors. Please test on Android/Windows/MacOS.');
         _isInitialized = false;
         return false;
      }
      
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Error initializing speech: $error'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
    } catch (e) {
      debugPrint('Exception initializing speech_to_text: $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        onDone();
        return;
      }
    }
    
    // Safety check just in case we are already listening
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        // We can optionally auto-stop if final result is reached
        if (result.finalResult) {
           onDone();
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  bool get isListening => _speechToText.isListening;
}
