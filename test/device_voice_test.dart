import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffs_sternenwelt/services/audio.dart';
import 'package:fluffs_sternenwelt/services/device_voice.dart';

class _UnplayedAssets implements FluffVoicePlayback {
  int stops = 0;
  @override
  Stream<void> get completed => const Stream.empty();
  @override
  Future<void> play(String asset) async =>
    throw StateError('Asset playback must not start for device narration');
  @override
  Future<void> stop() async { stops++; }
}
class _SpokenText implements FluffTextPlayback {
  final events = StreamController<void>.broadcast(sync: true);
  final spoken = <String>[];
  @override
  Stream<void> get completed => events.stream;
  @override
  Future<void> play(String text) async { spoken.add(text); }
  @override
  Future<void> stop() async {}
}

void main() {
  test('German voice matcher prefers de-DE offline and ignores network voices', () {
    expect(germanVoiceCandidate([
      {'name':'Online German', 'locale':'de-DE','network_required':true},
      {'name':'Austrian local', 'locale':'de-AT','network_required':false},
      {'name':'German local', 'locale':'de-DE','network_required':false},
    ])?['name'], 'German local');
    expect(germanVoiceCandidate([
      {'name':'Network','locale':'de-DE','network_required':'true'},
      {'name':'Unknown','locale':'de-DE'}
    ]), isNull);
    expect(germanVoiceCandidate([
      {'name':'Unknown','locale':'de-DE'}
    ], allowUnspecified:true)?['name'], 'Unknown');
    expect(germanVoiceCandidate(null), isNull);
  });

  test('Simple child narration uses Android TTS without starting the asset player', () async {
    final assets = _UnplayedAssets();
    final text = _SpokenText();
    final audio = FluffAudio.forTesting(assets, text:text);
    final task = audio.narrate(['Bitte räume dein Spielzeug weg.'], preferFluff:false);
    for (var i=0;i<20 && text.spoken.isEmpty;i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(text.spoken, ['Bitte räume dein Spielzeug weg.']);
    expect(assets.stops, 0);
    text.events.add(null);
    await task;
    await audio.stop();
    await text.events.close();
  });
}
