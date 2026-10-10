import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'pro_voice.dart';

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
  FluffAudio.forTesting(FluffVoicePlayback playback) : _playback = playback;
  static final instance = FluffAudio._();
  FluffVoicePlayback? _playback;
  AudioPlayer? _effectPlayer;
  FluffVoicePlayback get _voice => _playback ??= _AssetVoicePlayback();
  AudioPlayer get _effect => _effectPlayer ??= AudioPlayer();
  Future<void> _voiceOperation = Future.value();
  Completer<void>? _clipFinished;
  bool _enabled = true;
  int _voiceRequest = 0;
  bool get enabled => _enabled;
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
    return file == null ? Future.value() : _speak(['audio/fluff/$file.wav']);
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
    return _speak(paths.cast<String>());
  }

  void _interrupt() {
    _voiceRequest++;
    final pending = _clipFinished;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  Future<void> _speak(List<String> assets) {
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
        await _voice.stop();
        for (final asset in assets) {
          if (!enabled || request != _voiceRequest) return;
          final finished = Completer<void>();
          _clipFinished = finished;
          final subscription = _voice.completed.listen((_) {
            if (!finished.isCompleted) finished.complete();
          }, onError: (Object error, StackTrace stack) {
            if (!finished.isCompleted) finished.complete();
          });
          try {
            await _voice.play(asset);
            await finished.future.timeout(const Duration(seconds: 40));
          } finally {
            await subscription.cancel();
            if (identical(_clipFinished, finished)) _clipFinished = null;
          }
        }
      } catch (_) {
        await _stopVoice();
      }
    }();
    _voiceOperation = operation;
    return operation;
  }

  Future<void> _stopVoice() async {
    try { await _playback?.stop(); } catch (_) {}
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
