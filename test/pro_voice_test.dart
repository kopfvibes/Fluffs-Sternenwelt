import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffs_sternenwelt/data/creative.dart';
import 'package:fluffs_sternenwelt/data/discovery.dart';
import 'package:fluffs_sternenwelt/services/audio.dart';
import 'package:fluffs_sternenwelt/services/pro_voice.dart';

class FakeVoicePlayback implements FluffVoicePlayback {
  final events = StreamController<void>.broadcast(sync: true);
  final played = <String>[];
  int stops = 0;
  Completer<void>? loading;
  bool fail = false;
  @override
  Stream<void> get completed => events.stream;
  @override
  Future<void> play(String asset) async {
    if (fail) throw StateError('Unavailable player');
    played.add(asset);
    final pending = loading;
    loading = null;
    if (pending != null) await pending.future;
  }
  @override
  Future<void> stop() async { stops++; }
  void finish() => events.add(null);
}

Future<void> flush() => Future<void>.delayed(Duration.zero);
String clip(String text) => proVoiceClips[proVoiceKey(text)]!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All production questions, choices and feedback have Fluff recordings', () {
    final factory = GameFactory(random: Random(492));
    final spoken = <String>{...lessonWords.values};
    for (final age in [2, 4, 5, 6, 8, 12]) {
      for (final game in gameIds.where((game) => game != 'memory')) {
        for (var n = 0; n < 350; n++) {
          final question = factory.question(game, age);
          spoken.addAll([...question.narration, question.explanation]);
          if (question.practice != null) {
            spoken.addAll([...question.practice!.narration, question.practice!.phrase,
              question.practice!.explanation]);
          }
        }
      }
    }
    for (final question in [...feelingQuestions, ...kindnessQuestions]) {
      spoken.addAll([...question.narration, question.explanation]);
    }
    spoken.addAll(coloringTitles);
    spoken.addAll(['Finde zwei gleiche Bilder.', 'Ein Paar gefunden!',
      'Schau dir die Bilder an. Du darfst es neu versuchen.',
      'Schau noch einmal hin. Du darfst dir Zeit nehmen.',
      'Du hast alle Paare gefunden. Dein Entdecker-Sticker ist in deinem Album.',
      'Du hast etwas Neues entdeckt. Dein Entdecker-Sticker ist in deinem Album.',
      'Freies Malen.', 'Dein Bild ist im Album gespeichert.',
      'Such dir eine Farbe aus. Male in deinem Tempo. Wenn du fertig bist, '
        'kannst du dein Bild im Album speichern.',
      'Willkommen in meinem Malatelier! Hier kannst du malen, '
        'ein Ausmalbild aussuchen und deine Bilder im Album anschauen.',
      'Rosa', 'Gelb', 'Grün', 'Blau', 'Lila', 'Rot', 'Braun', 'Schwarz', 'Weiß']);
    expect(spoken.where((text) => !proVoiceClips.containsKey(proVoiceKey(text))),
      isEmpty, reason: 'Every Pro text must use the recorded Fluff voice.');
  });

  test('Every recording is bundled and matches the generated voice manifest', () async {
    final manifest = jsonDecode(File('pro-voice-manifest.json').readAsStringSync())
      as Map<String, dynamic>;
    expect(manifest['voice_name'], 'Fluff');
    final clips = manifest['clips'] as List;
    expect(clips.length, proVoiceClips.length);
    for (final raw in clips) {
      final entry = raw as Map<String, dynamic>;
      expect(proVoiceClips[entry['key']], entry['asset']);
      final bytes = await rootBundle.load('assets/${entry['asset']}');
      expect(bytes.lengthInBytes, entry['bytes']);
      expect(sha256.convert(bytes.buffer.asUint8List(bytes.offsetInBytes,
        bytes.lengthInBytes)).toString(), entry['sha256']);
      expect(entry['duration'] as num, greaterThan(.15));
    }
  });

  test('Spoken answers follow their visible order, including pattern names', () {
    const question = LearningQuestion('Was kommt als Nächstes?', '⭐ 💙 ?',
      ['💙', '⭐', '🔵'], 0, '');
    expect(question.narration, ['Was kommt als Nächstes?', 'Du kannst wählen:',
      'Herz', 'Stern', 'blauer Kreis']);
  });

  late FakeVoicePlayback voice;
  late FluffAudio audio;
  setUp(() {
    voice = FakeVoicePlayback();
    audio = FluffAudio.forTesting(voice);
  });
  tearDown(() async { await audio.stop(); await voice.events.close(); });

  test('A question reads every answer sequentially without overlaps', () async {
    final sequence = ['Wie viele Sterne siehst du?', 'Du kannst wählen:', '3', '1', '2'];
    final pending = audio.readAll(sequence);
    for (var i = 0; i < sequence.length; i++) {
      await flush();
      expect(voice.played, sequence.take(i + 1).map(clip).toList());
      voice.finish();
    }
    await pending;
  });

  test('A new answer interrupts the question and cancels its remaining choices', () async {
    final old = audio.readAll(['Welche Form ist das?', 'Du kannst wählen:', 'Kreis']);
    await flush();
    final reply = audio.read('Schau noch einmal hin. Du darfst dir Zeit nehmen.');
    await flush();
    expect(voice.played, [clip('Welche Form ist das?'),
      clip('Schau noch einmal hin. Du darfst dir Zeit nehmen.')]);
    voice.finish();
    await Future.wait([old, reply]);
  });

  test('Turning sound off stops the whole queue and allows a clean later replay', () async {
    final old = audio.readAll(['Welche Form ist das?', 'Du kannst wählen:', 'Kreis']);
    await flush();
    audio.enabled = false;
    await old;
    await audio.read('Dein Bild ist im Album gespeichert.');
    expect(voice.played, [clip('Welche Form ist das?')]);
    expect(voice.stops, greaterThan(0));
    audio.enabled = true;
    final replay = audio.read('Dein Bild ist im Album gespeichert.');
    await flush();
    expect(voice.played.last, clip('Dein Bild ist im Album gespeichert.'));
    voice.finish();
    await replay;
  });

  test('Stopping a page prevents remaining clips and cancels a pending replay', () async {
    final old = audio.readAll(['Welche Form ist das?', 'Kreis']);
    final replay = audio.read('Was kommt als Nächstes?');
    await audio.stop();
    await Future.wait([old, replay]);
    expect(voice.played, isEmpty);
  });

  test('A request loading an asset cannot overlap or block its replacement', () async {
    final loading = Completer<void>();
    voice.loading = loading;
    final old = audio.readAll(['Welche Form ist das?', 'Kreis']);
    await flush();
    final replacement = audio.read('Dein Bild ist im Album gespeichert.');
    await flush();
    expect(voice.played.length, 1);
    final stopsBeforeReady = voice.stops;
    loading.complete();
    await flush();
    expect(voice.stops, greaterThan(stopsBeforeReady));
    expect(voice.played, [clip('Welche Form ist das?'),
      clip('Dein Bild ist im Album gespeichert.')]);
    voice.finish();
    await Future.wait([old, replacement]);
  });

  test('An unavailable clip or player never switches to another voice', () async {
    await audio.read('An unrecorded sentence');
    expect(voice.played, isEmpty);
    voice.fail = true;
    await audio.read('Welche Form ist das?');
    expect(voice.played, isEmpty);
    voice.fail = false;
    final retry = audio.read('Welche Form ist das?');
    await flush();
    voice.finish();
    await retry;
    expect(voice.played, [clip('Welche Form ist das?')]);
  });
}
