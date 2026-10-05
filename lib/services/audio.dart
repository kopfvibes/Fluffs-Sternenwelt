import 'package:audioplayers/audioplayers.dart';

class FluffAudio {
  FluffAudio._();
  static final instance = FluffAudio._();
  AudioPlayer? _voicePlayer, _effectPlayer;
  AudioPlayer get _voice => _voicePlayer ??= AudioPlayer();
  AudioPlayer get _effect => _effectPlayer ??= AudioPlayer();
  bool _enabled = true;
  int _voiceRequest = 0;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) stop();
  }

  final Map<String, String> _files = {
    'welcome': 'welcome_01',
    'success': 'star_success_01',
    'stars': 'star_jar_01',
    'bedtime': 'bedtime_01',
    'mission': 'mission_start_01',
    'glücklich': 'mood_happy_01',
    'traurig': 'mood_sad_01',
    'wütend': 'mood_angry_01',
    'unsicher': 'mood_unsure_01',
    'müde': 'mood_tired_01',
    'stolz': 'mood_proud_01',
  };
  Future<void> say(String key) async {
    if (!enabled || !_files.containsKey(key)) return;
    final request = ++_voiceRequest;
    try {
      await _voice.stop();
      if (!enabled || request != _voiceRequest) return;
      await _voice.setVolume(.70);
      if (!enabled || request != _voiceRequest) return;
      await _voice.play(AssetSource('audio/fluff/${_files[key]}.wav'));
    } catch (_) {}
  }

  Future<void> star() async {
    if (!enabled) return;
    try {
      await _effect.setVolume(.30);
      await _effect.play(AssetSource('audio/sfx/star_collect.wav'));
    } catch (_) {}
  }

  Future<void> stop() async {
    _voiceRequest++;
    try {
      await _voicePlayer?.stop();
      await _effectPlayer?.stop();
    } catch (_) {}
  }
}
