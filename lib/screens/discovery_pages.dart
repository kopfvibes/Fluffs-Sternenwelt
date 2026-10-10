import 'dart:async';
import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../data/discovery.dart';
import '../services/audio.dart';
import '../widgets/common.dart';
import 'creative_pages.dart';
import 'parents_screen.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller,
    builder: (context, _) => Column(children: [
    ScreenTitle('Fluffs Entdeckerwelt'),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Row(children: [
          FluffSprite(pose: 'explorer', size: 122, animate: controller.data.motion),
          const Expanded(child: Text('Spielen. Malen. Entdecken.\nIn deinem Tempo.',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 10),
        if (!controller.proActive) ...[
          const GlossyPanel(child: Text(
            'Die Lernspiele und das Malatelier gehören zu Fluff Pro. '
            'Deine Eltern können sie öffnen.')),
          const SizedBox(height: 12),
        ],
        for (final id in gameIds)
          Padding(padding: const EdgeInsets.only(bottom: 12),
            child: GlossyPanel(onTap: () => _open(context, id),
              child: Row(children: [
                ArtIcon(gameArtwork[id]!, size: 40),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(gameTitles[id]!, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
                    Text(gameDescriptions[id]!),
                  ])),
                Icon(!controller.proActive ? Icons.lock_outline_rounded
                  : controller.gameCount(id) > 0 ? Icons.verified_rounded
                  : Icons.chevron_right_rounded, color: blue),
              ]))),
        GlossyButton('Fluffs Malatelier', key: const ValueKey('open-studio'),
          color: green, icon: controller.proActive ? Icons.brush_rounded
            : Icons.lock_outline_rounded, onPressed: () => _openStudio(context)),
        const SizedBox(height: 14),
        Text('Meine Entdecker-Sticker', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 9),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final id in gameIds)
            Semantics(label: '${gameTitles[id]}: '
              '${controller.gameCount(id) > 0 ? 'entdeckt' : 'noch nicht entdeckt'}',
              child: CircleAvatar(radius: 26,
                backgroundColor: controller.gameCount(id) > 0 ? gold : Colors.white,
                child: controller.gameCount(id) > 0
                  ? ArtIcon(gameArtwork[id]!, size: 32)
                  : const Icon(Icons.star_border_rounded, color: blue, size: 30))),
        ]),
        const SizedBox(height: 12),
        const Text('Jedes Abenteuer darfst du wiederholen. Es gibt keinen Zeitdruck.'),
      ])),
  ]));

  void _openStudio(BuildContext context) {
    if (!controller.proActive) {
      _showProGate(context, 'Das Malatelier gehört zu Fluff Pro. '
        'Deine Eltern können es im Elternbereich öffnen.');
      return;
    }
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) =>
      CreativeStudioPage(controller: controller)));
  }

  void _open(BuildContext context, String id) {
    if (!controller.proActive) {
      _showProGate(context, 'Dieses Lernspiel gehört zu Fluff Pro. '
        'Deine Eltern können den Spielbereich im Elternbereich öffnen.');
      return;
    }
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) =>
      LearningGamePage(controller: controller, game: id)));
  }

  void _showProGate(BuildContext context, String message) {
    showDialog<void>(context: context, builder: (dialog) => AlertDialog(
        title: const Text('Frag deine Eltern'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(dialog),
          child: const Text('Okay')),
          TextButton(onPressed: () {
            Navigator.pop(dialog);
            openParents(context, controller);
          }, child: const Text('Mit meinen Eltern öffnen'))],
      ));
  }
}

class LearningGamePage extends StatefulWidget {
  const LearningGamePage({super.key, required this.controller, required this.game,
    this.factory});
  final AppController controller;
  final String game;
  final GameFactory? factory;
  @override
  State<LearningGamePage> createState() => _LearningGamePageState();
}

class _LearningGamePageState extends State<LearningGamePage> {
  late final GameFactory factory;
  late final String childId;
  late final int age;
  late final List<int> cards;
  final open = <int>{}, matched = <int>{};
  int? first;
  Timer? timer;
  LearningQuestion? question;
  int round = 0;
  bool answered = false, finished = false, saving = false;
  String feedback = '';
  @override
  void initState() {
    super.initState();
    childId = widget.controller.child.id;
    age = widget.controller.child.age;
    factory = widget.factory ?? GameFactory();
    cards = factory.memoryCards(age);
    if (widget.game != 'memory') nextQuestion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) readPrompt();
    });
  }
  void readPrompt() {
    if (!widget.controller.data.sound || !widget.controller.proActive) return;
    FluffAudio.instance.read(widget.game == 'memory' ? 'Finde zwei gleiche Bilder.'
      : '${question!.prompt} Du kannst wählen: '
        '${question!.answers.map((a) => symbolNames[a] ?? a).join('. ')}.');
  }
  void nextQuestion() {
    final q = factory.question(widget.game, age);
    final order = List.generate(q.answers.length, (i) => i)..shuffle(factory.random);
    question = LearningQuestion(q.prompt, q.visual,
      order.map((i) => q.answers[i]).toList(), order.indexOf(q.correct), q.explanation);
    answered = false;
    feedback = '';
  }
  @override
  void dispose() { timer?.cancel(); FluffAudio.instance.stop(); super.dispose(); }

  void chooseCard(int i) {
    if (timer?.isActive == true || open.contains(i) || matched.contains(i) || finished) {
      return;
    }
    setState(() { open.add(i); feedback = ''; });
    if (first == null) { first = i; return; }
    final previous = first!;
    first = null;
    if (cards[previous] == cards[i]) {
      setState(() { matched.addAll([previous, i]); feedback = 'Ein Paar gefunden!'; });
      if (matched.length == cards.length) {
        timer = Timer(const Duration(milliseconds: 350), finish);
      }
    } else {
      setState(() => feedback = 'Schau dir die Bilder an. Du darfst es neu versuchen.');
      timer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => open.removeAll([previous, i]));
      });
    }
  }

  void chooseAnswer(int i) {
    if (answered || finished) return;
    setState(() {
      if (i == question!.correct) {
        answered = true;
        feedback = question!.explanation;
      } else {
        feedback = 'Schau noch einmal hin. Du darfst dir Zeit nehmen.';
      }
    });
    if (widget.controller.data.sound) FluffAudio.instance.read(feedback);
  }

  Future<void> finish() async {
    if (finished || saving || !mounted) return;
    setState(() => saving = true);
    try {
      await widget.controller.completeGame(widget.game, childId: childId);
      if (mounted) {
        setState(() { finished = true; saving = false; });
        if (widget.controller.data.sound) FluffAudio.instance.star();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          feedback = 'Dein Fortschritt konnte nicht gespeichert werden. '
            'Du kannst es noch einmal versuchen.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(gameTitles[widget.game]!)),
      body: WorldBackground(child: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          if (!widget.controller.proActive) ...[
            const Text('Dieses Spiel wird im Elternbereich mit Fluff Pro geöffnet.'),
          ] else if (finished) ...[
            FluffSprite(pose: 'proud', size: 200,
              animate: widget.controller.data.motion),
            const Text('Entdeckt!', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('Du hast ${gameTitles[widget.game]} ausprobiert. '
              'Dein Entdecker-Sticker ist in deinem Album.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GlossyButton('Noch einmal spielen', onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) =>
                LearningGamePage(controller: widget.controller, game: widget.game)));
            }),
            const SizedBox(height: 12),
            GlossyButton('Zur Entdeckerwelt', color: green,
              onPressed: () => Navigator.pop(context)),
          ] else ...[
            FluffSprite(pose: 'explorer', size: 126,
              animate: widget.controller.data.motion),
            const Text('In deinem Tempo. Du darfst jederzeit eine Pause machen.',
              textAlign: TextAlign.center),
            const SizedBox(height: 18),
            TextButton.icon(onPressed: widget.controller.data.sound ? readPrompt : null,
              icon: const Icon(Icons.volume_up_rounded), label: const Text('Vorlesen')),
            if (widget.game == 'memory') ...[
              const Text('Finde zwei gleiche Bilder.', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              GridView.count(crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
                children: [for (var i = 0; i < cards.length; i++)
                  Semantics(label: matched.contains(i) ? 'Gefundenes Paar' : 'Karte ${i + 1}',
                    child: InkWell(key: ValueKey('memory-card-$i'),
                      borderRadius: BorderRadius.circular(22), onTap: () => chooseCard(i),
                      child: Container(decoration: BoxDecoration(
                        color: matched.contains(i) ? const Color(0xffd1f8de)
                          : open.contains(i) ? Colors.white : const Color(0xffb6e4ff),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: blue, width: 2)),
                        child: Center(child: open.contains(i) || matched.contains(i)
                          ? ArtIcon(['teddy', 'book', 'moon', 'game', 'tooth', 'bag'][cards[i]],
                            size: 64)
                          : const Icon(Icons.star_rounded, color: blue, size: 62))))),
                ]),
              if (matched.length == cards.length && !saving)
                GlossyButton('Sticker speichern', onPressed: finish),
            ] else ...[
              Text('Entdeckung ${round + 1} von 5', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(question!.prompt, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              GlossyPanel(child: Wrap(alignment: WrapAlignment.center,
                spacing: 10, runSpacing: 10, children: [
                  for (final symbol in question!.visual.trim().split(RegExp(r'\s+')))
                    LearningSymbol(symbol, size: widget.game == 'shapes' ? 82
                      : widget.game == 'feelings' ? 100 : 42),
                ])),
              const SizedBox(height: 18),
              for (var i = 0; i < question!.answers.length; i++)
                Padding(padding: const EdgeInsets.only(bottom: 11),
                  child: widget.game == 'patterns'
                    ? Semantics(button: true, label: symbolNames[question!.answers[i]],
                        child: GlossyPanel(key: ValueKey('answer-$i'),
                          color: answered && i == question!.correct ? green :
                            const Color(0xffb6e4ff),
                          onTap: answered ? null : () => chooseAnswer(i),
                          child: Center(child: LearningSymbol(question!.answers[i], size: 42))))
                    : GlossyButton(question!.answers[i], key: ValueKey('answer-$i'),
                        color: answered && i == question!.correct ? green : blue,
                        onPressed: answered ? null : () => chooseAnswer(i))),
              if (answered) GlossyButton(round == 4 ? 'Sticker sammeln' : 'Weiter',
                key: const ValueKey('next-question'), color: green,
                onPressed: saving ? null : () {
                  if (round == 4) { finish(); } else {
                    setState(() { round++; nextQuestion(); });
                    readPrompt();
                  }
                }),
            ],
            if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 18),
              child: GlossyPanel(child: Text(feedback, textAlign: TextAlign.center))),
            if (saving) const Center(child: Padding(padding: EdgeInsets.all(18),
              child: CircularProgressIndicator())),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Ich mache eine Pause')),
          ],
        ])))),
  );
}

class LearningSymbol extends StatelessWidget {
  const LearningSymbol(this.symbol, {super.key, required this.size});
  final String symbol;
  final double size;
  @override
  Widget build(BuildContext context) {
    const circles = {'🔵': blue, '🟡': gold, '🟣': Color(0xff9a65d6), '🟢': green};
    const artwork = {'💙': 'heart', '🧸': 'teddy', '📘': 'book', '🌙': 'moon',
      '🧥': 'shirt', '🧩': 'help', '🤝': 'family'};
    const faces = {'😢': 'sad', '😠': 'angry', '🥱': 'tired', '😊': 'proud',
      '😟': 'unsure', '😄': 'proud'};
    final circle = circles[symbol];
    if (circle != null) {
      return Container(width: size, height: size,
        decoration: BoxDecoration(color: circle, shape: BoxShape.circle));
    }
    final art = artwork[symbol];
    if (art != null) return ArtIcon(art, size: size);
    final face = faces[symbol];
    if (face != null) return FluffSprite(pose: face, size: size, animate: false);
    final icon = switch (symbol) {
      '⭐' || '★' => Icons.star_rounded,
      '●' => Icons.circle,
      '▲' => Icons.change_history_rounded,
      '■' => Icons.square,
      '🌸' => Icons.local_florist_rounded,
      '🍀' => Icons.park_rounded,
      '☀️' => Icons.wb_sunny_rounded,
      '🌈' => Icons.looks_rounded,
      '💧' => Icons.water_drop_rounded,
      '✋' => Icons.back_hand_rounded,
      '🚦' => Icons.traffic_rounded,
      '🌬️' => Icons.air_rounded,
      _ => null,
    };
    if (icon == null) {
      return Text(symbol,
        style: TextStyle(fontSize: size, color: blue, fontWeight: FontWeight.w900));
    }
    final color = switch (symbol) {
      '⭐' || '☀️' => gold,
      '🌸' => const Color(0xffef5d8a),
      '🍀' => green,
      _ => blue,
    };
    return Icon(icon, size: size, color: color);
  }
}
