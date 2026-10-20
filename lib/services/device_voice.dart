import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

abstract class FluffTextPlayback {
  Stream<void> get completed;
  Future<void> play(String text);
  Future<void> stop();
}

/// Android TTS engines do not all describe offline voices the same way.
/// Prefer an explicitly offline German voice. A voice without a network flag
/// can still be used when the engine confirms German is installed locally.
Map<String, String>? germanVoiceCandidate(dynamic raw, {bool allowUnspecified = false}) {
  if (raw is! List) return null;
  final candidates = <Map<String, String>>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final locale = (item['locale'] ?? '').toString();
    final name = (item['name'] ?? '').toString();
    if (name.isEmpty || !locale.toLowerCase().startsWith('de')) continue;
    final flag = item['network_required']?.toString().toLowerCase();
    if (flag == 'true' || flag == '1') continue;
    if (!allowUnspecified && flag != 'false' && flag != '0') continue;
    candidates.add({'name': name, 'locale': locale});
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    int rank(Map<String, String> v) =>
      v['locale']!.toLowerCase().replaceAll('_', '-').startsWith('de-de') ? 0 : 1;
    return rank(a).compareTo(rank(b));
  });
  return candidates.first;
}

/// Parent-created instructions stay on the phone. Missing TTS engines and
/// voice errors are reported to the interface rather than silently swallowed.
class GermanDeviceVoice implements FluffTextPlayback {
  final _tts = FlutterTts();
  final _events = StreamController<void>.broadcast(sync: true);
  Future<void>? _preparing;
  @override
  Stream<void> get completed => _events.stream;

  Future<void> _prepare() async {
    _tts.setCompletionHandler(() => _events.add(null));
    _tts.setCancelHandler(() => _events.add(null));
    _tts.setErrorHandler((message) =>
      _events.addError(StateError('Die Android-Vorlesestimme meldet: $message')));
    await _tts.awaitSpeakCompletion(false);

    dynamic raw;
    try { raw = await _tts.getVoices; } catch (_) { /* Some engines omit voices. */ }
    Map<String, String>? voice = germanVoiceCandidate(raw);
    dynamic installed;
    if (voice == null) {
      try { installed = await _tts.isLanguageInstalled('de-DE'); }
      catch (_) { /* Older engines do not support the query. */ }
      if (installed == false || installed == 0) {
        throw StateError('Keine deutsche Vorlesestimme installiert. Öffne die '
          'Android-Einstellungen für Text-in-Sprache und lade Deutsch herunter.');
      }
      // Use an unflagged German voice if one is available. Do not select
      // voices that explicitly require network access.
      voice = germanVoiceCandidate(raw, allowUnspecified: true);
    }

    final locale = voice?['locale'] ?? 'de-DE';
    final result = await _tts.setLanguage(locale);
    if (result is num && result < 0) {
      throw StateError('Deutsch ist für die Vorlesefunktion nicht verfügbar. '
        'Bitte eine deutsche Text-in-Sprache-Stimme installieren.');
    }
    if (voice != null) {
      try { await _tts.setVoice(voice); }
      catch (_) { /* Keep the selected German language as fallback. */ }
    }
    await _tts.setSpeechRate(.44);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  Future<void> play(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await (_preparing ??= _prepare());
      final result = await _tts.speak(text, focus: true);
      if (result != 1) throw StateError('Die Vorlesestimme konnte nicht starten.');
    } catch (_) {
      // Recheck installed voices after Android language settings change.
      _preparing = null;
      rethrow;
    }
  }

  @override
  Future<void> stop() async { await _tts.stop(); }
}
