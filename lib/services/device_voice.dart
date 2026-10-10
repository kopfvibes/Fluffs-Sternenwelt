import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

abstract class FluffTextPlayback {
  Stream<void> get completed;
  Future<void> play(String text);
  Future<void> stop();
}

/// Parent-written names and instructions stay on the device.
/// Only an installed German voice that does not require the network is used.
class GermanDeviceVoice implements FluffTextPlayback {
  final _tts = FlutterTts();
  final _events = StreamController<void>.broadcast(sync: true);
  Future<void>? _preparing;
  @override
  Stream<void> get completed => _events.stream;

  Future<void> _prepare() async {
    _tts.setCompletionHandler(() => _events.add(null));
    _tts.setCancelHandler((_) => _events.add(null));
    _tts.setErrorHandler((_) => _events.add(null));
    final raw = await _tts.getVoices;
    final voices = (raw as List).whereType<Map>().where((voice) {
      final locale = (voice['locale'] ?? '').toString().toLowerCase();
      final network = voice['network_required'];
      return locale.startsWith('de') &&
          (network == false || network.toString() == 'false');
    }).toList();
    if (voices.isEmpty) {
      throw StateError('Bitte eine deutsche Offline-Vorlesestimme in den '
          'Sprachausgabe-Einstellungen des Handys installieren.');
    }
    final voice = voices.first;
    await _tts.setLanguage(voice['locale'].toString());
    await _tts.setVoice({'name': voice['name'].toString(),
      'locale': voice['locale'].toString()});
    await _tts.setSpeechRate(.42);
    await _tts.setVolume(.75);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(false);
  }

  @override
  Future<void> play(String text) async {
    final preparing = _preparing ??= _prepare();
    try {
      await preparing;
    } catch (_) {
      _preparing = null;
      rethrow;
    }
    final result = await _tts.speak(text, focus: true);
    if (result != 1) throw StateError('Die Vorlesestimme ist nicht bereit.');
  }

  @override
  Future<void> stop() async { await _tts.stop(); }
}
