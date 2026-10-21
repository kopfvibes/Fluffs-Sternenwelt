import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../data/companion.dart';
import 'device_voice.dart';
import 'pro_voice.dart';
import 'offline_fluff_narration.dart';

abstract class FluffVoicePlayback {
  Stream<void> get completed;
  Future<void> play(String asset);
  Future<void> stop();
}

class _AssetVoicePlayback implements FluffVoicePlayback {
  final player = AudioPlayer();
  @override
  Stream<void> get completed => player.onPlayerComplete;
  @override
  Future<void> play(String asset) => player.play(AssetSource(asset), volume: .70);
  @override
  Future<void> stop() => player.stop();
}

class FluffAudio {
  FluffAudio._();
  FluffAudio.forTesting(FluffVoicePlayback playback, {FluffTextPlayback? text})
    : _playback = playback, _textPlayback = text;
  static final instance = FluffAudio._();
  FluffVoicePlayback? _playback;
  FluffTextPlayback? _textPlayback;
  AudioPlayer? _effectPlayer;
  FluffVoicePlayback get _voice => _playback ??= _AssetVoicePlayback();
  FluffTextPlayback get _text => _textPlayback ??= GermanDeviceVoice();
  AudioPlayer get _effect => _effectPlayer ??= AudioPlayer();
  Future<void> _voiceOperation = Future.value();
  Completer<void>? _clipFinished;
  bool _enabled = true;
  int _voiceRequest = 0;
  int get requestId => _voiceRequest;
  bool get enabled => _enabled;
  final speaking = ValueNotifier<bool>(false);
  final voiceProblem = ValueNotifier<String?>(null);
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) stop();
  }

  static const _files = {
    'welcome': 'welcome_01', 'success': 'star_success_01',
    'stars': 'star_jar_01', 'bedtime': 'bedtime_01',
    'mission': 'mission_start_01', 'glücklich': 'mood_happy_01',
    'traurig': 'mood_sad_01', 'wütend': 'mood_angry_01',
    'unsicher': 'mood_unsure_01', 'müde': 'mood_tired_01',
    'stolz': 'mood_proud_01',
  };

  Future<void> say(String key) {
    final file = _files[key];
    return file == null ? Future.value()
      : _speak([_SpokenPart.asset('audio/fluff/$file.wav')]);
  }

  Future<void> star() async {
    if (!enabled) return;
    try {
      await _effect.setVolume(.30);
      if (!enabled) return;
      await _effect.play(AssetSource('audio/sfx/star_collect.wav'));
    } catch (_) {}
  }

  Future<void> read(String text) => readAll([text]);

  Future<void> readAll(Iterable<String> texts) {
    final paths = texts.map((text) => proVoiceClips[proVoiceKey(text)]).toList();
    // Every published Pro text has a recorded clip. Never substitute a device voice.
    if (paths.isEmpty || paths.any((path) => path == null)) return Future.value();
    return _speak(paths.cast<String>().map(_SpokenPart.asset).toList());
  }

  /// Full child-page reading, including parent-written text. The fixed Pro
  /// instructions use Fluff; custom text uses an installed local German voice.
  /// Strict game recording playback above never silently changes voices.
  Future<void> narrate(Iterable<String> texts, {bool preferFluff = true}) {
    final parts = <_SpokenPart>[];
    for (final raw in texts) {
      final text = raw.replaceAll('\n', ' ').trim();
      if (text.isEmpty) continue;
      final number = int.tryParse(text);
      final tokens = preferFluff && number != null
        ? spokenNumber(number) : [text];
      for (final token in tokens) {
        final asset = preferFluff
          ? offlineFluffNarrationClips[proVoiceKey(token)] ??
              proVoiceClips[proVoiceKey(token)]
          : null;
        parts.add(asset == null ? _SpokenPart.text(token)
          : _SpokenPart.asset(asset));
      }
    }
    return parts.isEmpty ? Future.value() : _speak(parts);
  }

  void _interrupt() {
    _voiceRequest++;
    speaking.value = false;
    final pending = _clipFinished;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  Future<void> _speak(List<_SpokenPart> parts) {
    if (!enabled) return Future.value();
    _interrupt();
    final request = _voiceRequest;
    final previous = _voiceOperation;
    // Stop immediately, then serialize preparation to avoid overlapping requests.
    final interrupted = _stopVoice();
    final operation = () async {
      await previous;
      await interrupted;
      if (!enabled || request != _voiceRequest) return;
      try {
        // Do not create and stop an unused asset player before Android TTS.
        // Certain devices reject stop() before the first asset has played.
        if (_playback != null) await _playback!.stop();
        voiceProblem.value = null;
        var textUnavailable = false;
        for (final part in parts) {
          if (!enabled || request != _voiceRequest) return;
          if (part.asset == null && textUnavailable) continue;
          final finished = Completer<void>();
          _clipFinished = finished;
          final events = part.asset != null ? _voice.completed : _text.completed;
          final subscription = events.listen((_) {
            if (!finished.isCompleted) finished.complete();
          }, onError: (Object error, StackTrace stack) {
            if (!finished.isCompleted) finished.completeError(error, stack);
          });
          try {
            speaking.value = true;
            if (part.asset != null) {
              await _voice.play(part.asset!);
            } else {
              await _text.play(part.text!);
            }
            final duration = part.asset != null
              ? const Duration(seconds: 35)
              : Duration(seconds: (12 + (part.text!.length ~/ 9)).clamp(15, 75));
            await finished.future.timeout(duration);
          } catch (error) {
            if (request != _voiceRequest) return;
            voiceProblem.value = part.asset == null
              ? error is StateError
                ? error.message.toString()
                : 'Die Vorlesestimme konnte nicht starten. Prüfe in den '
                  'Android-Einstellungen die Text-in-Sprache-Ausgabe und die Medienlautstärke.'
              : 'Die Fluff-Aufnahme konnte nicht abgespielt werden. Bitte erneut versuchen.';
            if (part.asset != null) rethrow;
            textUnavailable = true;
          } finally {
            await subscription.cancel();
            if (identical(_clipFinished, finished)) _clipFinished = null;
          }
        }
      } catch (_) {
        await _stopVoice();
      } finally {
        if (request == _voiceRequest) speaking.value = false;
      }
    }();
    _voiceOperation = operation;
    return operation;
  }

  Future<void> _stopVoice() async {
    try { await _playback?.stop(); } catch (_) {}
    try { await _textPlayback?.stop(); } catch (_) {}
  }

  Future<void> stop() {
    _interrupt();
    final previous = _voiceOperation;
    final interrupted = _stopVoice();
    final operation = () async {
      await previous;
      await interrupted;
      await _stopVoice();
      try { await _effectPlayer?.stop(); } catch (_) {}
    }();
    _voiceOperation = operation;
    return operation;
  }
}

class _SpokenPart {
  const _SpokenPart.asset(this.asset) : text = null;
  const _SpokenPart.text(this.text) : asset = null;
  final String? asset, text;
}
