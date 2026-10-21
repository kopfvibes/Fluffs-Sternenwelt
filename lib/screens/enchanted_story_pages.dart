import 'dart:async';
import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../data/enchanted_stories.dart';
import '../services/audio.dart';
import '../widgets/common.dart';

/// Keeps the existing, recognizable Fluff art instead of inventing another mascot.
class EnchantedStoryLibrary extends StatelessWidget {
  const EnchantedStoryLibrary({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final today = dailyEnchantedStory(controller.now);
      final finished = controller.storyDone(today);
      final read = <int>[
        for (var i = 0; i < enchantedStories.length; i++)
          if (i != today && controller.storyDone(i)) i,
      ];
      final tale = enchantedStories[today];
      return Scaffold(backgroundColor: const Color(0xff071b49),
        body: WorldBackground(scene: true, night: true,
          child: SafeArea(child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Row(children: [
                IconButton(key: const ValueKey('stories-back'),
                  color: Colors.white, icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.maybePop(context)),
                const Expanded(child: Text('Fluffs Geschichtenwald',
                  style: TextStyle(color: Colors.white, fontSize: 24,
                    fontWeight: FontWeight.w900))),
              ]),
              const Text('60 kleine Abenteuer · Jeden Tag eine neue Geschichte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xffffe4a2),
                  fontWeight: FontWeight.w800)),
              SizedBox(height: 205, child: Stack(alignment: Alignment.center,
                children: [
                  const Positioned(left: 25, top: 18,
                    child: Icon(Icons.auto_awesome_rounded, color: gold, size: 36)),
                  const Positioned(right: 27, top: 15,
                    child: Icon(Icons.star_rounded, color: Color(0xffffe69e), size: 30)),
                  const Positioned(right: 49, bottom: 16,
                    child: Text('🍄', style: TextStyle(fontSize: 48))),
                  FluffSprite(pose: 'welcome', size: 191,
                    animate: controller.data.motion),
                ])),
              GlossyPanel(radius: 28, child: Column(children: [
                const Text('✨ HEUTE FÜR DICH ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                Text(tale.title, textAlign: TextAlign.center,
                  style: const TextStyle(color: ink, fontSize: 24,
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                Text("Mit Fluff und ${tale.friend}",
                  style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 11),
                Text(finished ? 'Schon entdeckt! Du darfst sie noch einmal erleben.'
                  : 'Drei Szenen, eine Mitmach-Idee und ein schöner Schluss.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 15),
                GlossyButton(finished ? 'Noch einmal erleben' : 'Geschichte starten',
                  key: const ValueKey('open-daily-story'),
                  icon: Icons.menu_book_rounded, color: gold,
                  onPressed: () => _openStory(context, today)),
              ])),
              const SizedBox(height: 18),
              Text("Mein Geschichtenschatz · ${read.length + (finished ? 1 : 0)} von 60",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Colors.white, fontSize: 18)),
              const SizedBox(height: 9),
              if (read.isEmpty)
                const GlossyPanel(child: Text(
                  'Nach dem Mitmachen findest du deine fertigen Geschichten hier wieder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16)))
              else for (final i in read)
                Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: GlossyPanel(onTap: () => _openStory(context, i),
                    child: Row(children: [
                      const Icon(Icons.auto_stories_rounded, color: ink),
                      const SizedBox(width: 12),
                      Expanded(child: Text(enchantedStories[i].title,
                        style: const TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w900))),
                      const Icon(Icons.chevron_right_rounded, color: ink),
                    ]))),
            ],
          ))));
    });
  void _openStory(BuildContext context, int index) {
    unawaited(FluffAudio.instance.stop());
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EnchantedStoryReader(controller: controller, index: index)));
  }
}

class EnchantedStoryReader extends StatefulWidget {
  const EnchantedStoryReader({super.key, required this.controller,
    required this.index});
  final AppController controller;
  final int index;
  @override
  State<EnchantedStoryReader> createState() => _EnchantedStoryReaderState();
}
class _EnchantedStoryReaderState extends State<EnchantedStoryReader> {
  int scene = 0;
  int? chosen;
  bool saved = false, saving = false;
  String? error;
  late final String childId;
  EnchantedStory get story => enchantedStories[widget.index];
  @override
  void initState() {
    super.initState();
    childId = widget.controller.child.id;
    saved = widget.controller.storyDone(widget.index, childId: childId);
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }
  void _changed() {
    if (!mounted) return;
    if (childId != widget.controller.child.id || !widget.controller.data.sound) {
      unawaited(FluffAudio.instance.stop());
    }
    if (childId != widget.controller.child.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { Navigator.maybePop(context); }
      });
    }
  }
  String get text => scene == 0 ? story.opening
    : scene == 1 ? story.challenge : story.ending;
  List<String> get spoken => [
    text,
    if (scene == 1) story.question,
    if (scene == 1 && chosen != null)
      chosen == 0 ? story.answerA : story.answerB,
    if (scene == 2) story.heart,
  ];
  void _read() {
    if (!mounted || !widget.controller.data.sound ||
        childId != widget.controller.child.id ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    unawaited(FluffAudio.instance.narrate(spoken,
      preferFluff: widget.controller.proActive));
  }
  void _advance(int value) {
    setState(() { scene = value; chosen = null; error = null; });
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }
  void _choose(int value) {
    setState(() => chosen = value);
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }
  Future<void> _finish() async {
    if (saving || childId != widget.controller.child.id) return;
    if (saved) { if (mounted) Navigator.pop(context); return; }
    setState(() { saving = true; error = null; });
    try {
      await widget.controller.completeStory(widget.index, childId: childId);
      if (mounted) { setState(() { saved = true; saving = false; }); }
    } catch (_) {
      if (mounted) setState(() {
        saving = false; error = 'Die Geschichte konnte nicht gespeichert werden.';
      });
    }
  }
  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    unawaited(FluffAudio.instance.stop());
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final visible = childId == widget.controller.child.id;
    return Scaffold(backgroundColor: const Color(0xff061a43),
      body: WorldBackground(scene: true, night: true,
        child: SafeArea(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Row(children: [
              IconButton(tooltip: 'Zurück zum Geschichtenwald',
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context)),
              Expanded(child: Text(story.title, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.w900))),
              IconButton(tooltip: 'Noch einmal vorlesen',
                key: const ValueKey('story-hear'),
                color: Colors.white, icon: const Icon(Icons.volume_up_rounded),
                onPressed: widget.controller.data.sound ? _read : null),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Icon(Icons.star_rounded,
                  color: i <= scene ? gold : const Color(0x88ffffff),
                  size: 28)))),
            const SizedBox(height: 7),
            Text("Szene ${scene + 1} von 3",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xffffe4a2),
                fontSize: 16, fontWeight: FontWeight.w900)),
            SizedBox(height: 220,
              child: Stack(alignment: Alignment.center, children: [
                const Positioned(left: 25, top: 26,
                  child: Icon(Icons.auto_awesome_rounded, color: gold, size: 36)),
                const Positioned(right: 19, top: 10,
                  child: Icon(Icons.star_rounded,
                    color: Color(0xffffe7a6), size: 26)),
                const Positioned(left: 22, bottom: 16,
                  child: Icon(Icons.local_florist_rounded,
                    color: Color(0xffffe3a0), size: 30)),
                Positioned(right: 12, bottom: 22,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_symbol(story.friend), style: const TextStyle(fontSize: 46)),
                    Text(story.friend, style: const TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w900)),
                  ])),
                FluffSprite(pose: scene == 2 ? 'proud' : 'welcome', size: 195,
                  animate: widget.controller.data.motion, onTap: _read),
              ])),
            Container(
              padding: const EdgeInsets.fromLTRB(19, 21, 19, 21),
              decoration: BoxDecoration(color: const Color(0xfffff7df),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xffffd569), width: 3),
                boxShadow: const [BoxShadow(color: Color(0x77ffd970),
                  blurRadius: 21, spreadRadius: 2)]),
              child: Column(children: [
                Text(text, key: const ValueKey('story-scene-text'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, height: 1.38,
                    color: ink, fontWeight: FontWeight.w800)),
                if (scene == 1) ...[
                  const SizedBox(height: 14),
                  Text(story.question, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: ink,
                      fontWeight: FontWeight.w900)),
                ],
                if (scene == 2) ...[
                  const SizedBox(height: 16),
                  const Icon(Icons.favorite_rounded, color: Color(0xffea678a)),
                  Text(story.heart, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w900, color: ink, height: 1.3)),
                ],
              ])),
            const SizedBox(height: 17),
            if (scene == 0)
              GlossyButton('Weiter zur nächsten Szene',
                key: const ValueKey('story-next'),
                color: gold, icon: Icons.arrow_forward_rounded,
                onPressed: visible ? () => _advance(1) : null),
            if (scene == 1) ...[
              if (chosen == null) ...[
                GlossyButton(story.optionA,
                  key: const ValueKey('story-choice-a'), color: gold,
                  onPressed: visible ? () => _choose(0) : null),
                const SizedBox(height: 10),
                GlossyButton(story.optionB,
                  key: const ValueKey('story-choice-b'),
                  color: const Color(0xffd4eeff),
                  onPressed: visible ? () => _choose(1) : null),
              ] else ...[
                GlossyPanel(child: Text(chosen == 0 ? story.answerA : story.answerB,
                  key: const ValueKey('story-choice-feedback'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.3,
                    fontWeight: FontWeight.w800))),
                const SizedBox(height: 10),
                GlossyButton('Schau, wie es weitergeht',
                  key: const ValueKey('story-resolve'), color: gold,
                  onPressed: visible ? () => _advance(2) : null),
              ],
            ],
            if (scene == 2) ...[
              if (saved)
                const GlossyPanel(child: Text(
                  '🌟 Geschafft! Diese Geschichte bleibt in deinem Schatz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              if (error != null) Text(error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 9),
              GlossyButton(saved ? 'Zurück zum Geschichtenwald'
                  : saving ? 'Einen Augenblick …' : 'Geschichte geschafft!',
                key: const ValueKey('story-complete'), color: gold,
                icon: Icons.auto_stories_rounded,
                onPressed: !visible || saving ? null : _finish),
            ],
            const SizedBox(height: 11),
            if (scene > 0 && scene < 2)
              TextButton.icon(onPressed: visible ? () => _advance(scene - 1) : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Noch einmal anschauen'),
                style: TextButton.styleFrom(foregroundColor: Colors.white)),
          ],
        ))));
  }
}
String _symbol(String friend) => switch (friend) {
  'Dotti' => '🍄',
  'Sternchen' || 'Sternschnuppe' => '🌟',
  'Mond' => '🌙',
  'Blume' => '🌼',
  'Glühwürmchen' => '✨',
  'Vogel' => '🐦',
  'Käfer' => '🐞',
  'Schnecke' => '🐌',
  'Fuchs' => '🦊',
  'Grashüpfer' => '🦗',
  'Alle Freunde' => '💛',
  _ => '⭐',
};
