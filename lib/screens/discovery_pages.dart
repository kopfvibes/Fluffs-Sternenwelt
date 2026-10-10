import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../data/discovery.dart';
import '../services/audio.dart';
import '../widgets/common.dart';
import '../widgets/learning_boards.dart';
import '../widgets/learning_symbol.dart';
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
  final lessonScroll = ScrollController();
  late final GameFactory factory;
  late final String childId;
  late final List<int> cards;
  late final LearningJourney journey;
  final open = <int>{}, matched = <int>{}, model = <int>{};
  int? first;
  bool mismatch = false, started = false, answered = false, practiced = false;
  bool finished = false, saving = false, showGroups = false, phraseTried = false;
  int round = 0, breaths = 0;
  int? selectedAnswer, talkSentence;
  String support = '', feedback = '';
  List<String> lastSpoken = [];
  LearningQuestion? question;
  ExplorationProgress? exploration;

  bool get available => mounted && widget.controller.proActive &&
    widget.controller.child.id == childId;
  bool get canSpeak => available && widget.controller.data.sound;
  bool get needsExploration => ['count', 'shapes', 'patterns'].contains(widget.game);
  bool get canAnswer => !needsExploration || exploration!.ready;
  bool get canContinue => answered && practiced;
  String get instruction => widget.game == 'memory' ? lessonWord('memory.explore')
    : widget.game == 'count' ? lessonWord(exploration!.ready ? 'count.ready' : 'count.explore')
    : widget.game == 'shapes' ? lessonWord(exploration!.ready ? 'shape.ready'
        : 'shape.${question!.shape}.explore')
    : widget.game == 'patterns' ? lessonWord(exploration!.ready ? 'pattern.ready' : 'pattern.explore')
    : widget.game == 'feelings' ? lessonWord('feelings.prompt') : question!.prompt;

  @override
  void initState() {
    super.initState();
    childId = widget.controller.child.id;
    widget.controller.addListener(stopIfUnavailable);
    journey = LearningJourney(widget.controller.child.age);
    factory = widget.factory ?? GameFactory();
    cards = factory.memoryCards(widget.controller.child.age);
    if (widget.game != 'memory') nextQuestion();
    lastSpoken = [lessonWord('intro.${widget.game}')];
    WidgetsBinding.instance.addPostFrameCallback((_) { if (canSpeak) readPrompt(); });
  }
  void stopIfUnavailable() { if (!canSpeak) FluffAudio.instance.stop(); }
  @override
  void dispose() {
    widget.controller.removeListener(stopIfUnavailable);
    FluffAudio.instance.stop();
    lessonScroll.dispose();
    super.dispose();
  }
  void readPrompt() { if (canSpeak) FluffAudio.instance.readAll(lastSpoken); }
  void coach(List<String> texts, {String? display}) {
    if (!available) return;
    setState(() { feedback = display ?? texts.join(' '); lastSpoken = texts; });
    readPrompt();
  }
  void start() {
    if (!available) return;
    setState(() => started = true);
    lessonScroll.jumpTo(0);
    coach(widget.game == 'memory' ? [instruction]
      : needsExploration ? [question!.prompt, instruction] : [instruction,
          if (widget.game == 'feelings') question!.prompt,
          'Du kannst wählen:', ...question!.answers], display: instruction);
  }
  void nextQuestion() {
    question = journey.next(factory, widget.game);
    exploration = ExplorationProgress(question!.explorationSteps,
      ordered: widget.game == 'patterns');
    answered = false; practiced = false; showGroups = false; phraseTried = false;
    selectedAnswer = null; talkSentence = null; support = ''; breaths = 0; feedback = '';
  }
  void help() {
    if (!available || finished || saving) return;
    journey.help();
    if (widget.game == 'memory') {
      showMemoryModel();
    } else {
      setState(() => showGroups = true);
      coach([lessonWord('help.${widget.game}')]);
    }
  }
  void touch(int index, {bool assisted = false}) {
    if (!available || !started || answered || finished || saving) return;
    if (assisted) journey.help();
    if (!exploration!.touch(index)) return;
    setState(() {});
    final texts = [widget.game == 'patterns' ? symbolNames[question!.unit[index]]!
      : widget.game == 'shapes' && question!.shape == 'circle'
        ? lessonWord('shape.circle.fact') : '${exploration!.visited.length}'];
    if (exploration!.ready) {
      if (widget.game == 'shapes' && question!.shape != 'circle') texts.add(question!.explanation);
      if (widget.game == 'patterns') texts.add(lessonWord('pattern.unit'));
      texts.addAll([instruction, 'Du kannst wählen:',
        ...question!.answers.map((a) => symbolNames[a] ?? a)]);
    }
    // Keep the last number visible while Fluff says it.
    coach(texts, display: exploration!.ready ? instruction : texts.first);
  }
  void countAgain() {
    if (!available || answered) return;
    journey.help();
    setState(() => exploration = ExplorationProgress(question!.explorationSteps));
    coach([lessonWord('count.explore')]);
  }
  void chooseAnswer(int i) {
    if (!available || !started || !canAnswer || answered || saving || finished) return;
    if (!question!.accepts(i)) {
      journey.help();
      final key = widget.game == 'count' ? 'count.retry' : widget.game == 'shapes'
        ? 'shape.retry' : widget.game == 'patterns' ? 'pattern.retry' : 'help.kindness';
      setState(() => showGroups = true);
      coach([lessonWord(key), if (['shapes','kindness'].contains(widget.game)) question!.explanation]);
      return;
    }
    setState(() {
      answered = true; selectedAnswer = i;
      practiced = !question!.personalFeeling && question!.practice == null;
    });
    if (question!.personalFeeling) {
      coach([lessonWord('feeling.${question!.answers[i]}'), lessonWord('feelings.support')]);
    } else if (question!.practice != null) {
      coach([question!.explanation, lessonWord('practice.intro'), question!.practice!.phrase]);
    } else {
      coach([if (widget.game == 'count') question!.answers[i], question!.explanation]);
    }
  }
  void chooseSupport(String value) {
    if (!available || !answered || !question!.personalFeeling || saving) return;
    setState(() { support = value; practiced = false; breaths = 0; talkSentence = null; });
    coach([lessonWord('$value.intro'), if (value == 'breathe') lessonWord('breathe.in')]);
  }
  void breathe() {
    if (!available || support != 'breathe' || practiced) return;
    setState(() { breaths++; if (breaths == 6) practiced = true; });
    coach([lessonWord(breaths == 6 ? 'breathe.done'
      : breaths.isEven ? 'breathe.in' : 'breathe.out')]);
  }
  void selectSentence(int i) {
    if (!available || support != 'talk' || practiced) return;
    setState(() => talkSentence = i);
    coach([lessonWord('talk.sentence.$i')]);
  }
  void completeSupport() {
    if (!available || practiced || (support == 'talk' && talkSentence == null) ||
        !['talk', 'pause'].contains(support)) { return; }
    setState(() => practiced = true);
    coach([lessonWord('$support.done')]);
  }
  void tryPhrase() {
    if (!available || question!.practice == null || phraseTried || !answered) return;
    setState(() => phraseTried = true);
    coach(question!.practice!.narration, display: question!.practice!.prompt);
  }
  void choosePractice(int i) {
    if (!available || !phraseTried || practiced) return;
    if (i != 0) {
      journey.help();
      coach([lessonWord('practice.retry'), question!.practice!.explanation, question!.practice!.phrase]);
      return;
    }
    setState(() => practiced = true);
    coach([question!.practice!.explanation]);
  }
  void chooseCard(int i) {
    if (!available || !started || finished || saving || mismatch || model.isNotEmpty ||
        open.contains(i) || matched.contains(i)) { return; }
    setState(() => open.add(i));
    if (first == null) {
      first = i;
      coach([lessonWord('memory.name.${cards[i]}'), lessonWord('memory.first')]);
      return;
    }
    final previous = first!;
    first = null;
    if (cards[previous] == cards[i]) {
      setState(() { matched.addAll([previous, i]); open.clear(); });
      coach([lessonWord('memory.name.${cards[i]}'), lessonWord(matched.length == cards.length
        ? 'memory.done' : 'memory.match')]);
    } else {
      journey.help();
      setState(() => mismatch = true);
      coach([lessonWord('memory.name.${cards[i]}'), lessonWord('memory.retry')]);
    }
  }
  void resetCards() {
    if (!available) return;
    setState(() { open.clear(); model.clear(); first = null; mismatch = false; });
    coach([lessonWord('memory.explore')]);
  }
  void showMemoryModel({bool all = false}) {
    if (!available || matched.length == cards.length) return;
    journey.help();
    setState(() {
      open.clear(); first = null; mismatch = false; model.clear();
      if (all) {
        model.addAll(List.generate(cards.length, (i) => i).where((i) => !matched.contains(i)));
      } else {
        final i = List.generate(cards.length, (i) => i).firstWhere((i) => !matched.contains(i));
        model.addAll([i, List.generate(cards.length, (j) => j)
          .firstWhere((j) => j != i && cards[j] == cards[i])]);
      }
    });
    coach([lessonWord(all ? 'memory.all' : 'memory.model')]);
  }
  void next() {
    if (!available || !canContinue || saving) return;
    if (round == 4) { finish(); return; }
    journey.complete();
    setState(() { round++; nextQuestion(); });
    lessonScroll.jumpTo(0);
    coach(needsExploration ? [question!.prompt, instruction]
      : [instruction, if (widget.game == 'feelings') question!.prompt,
          'Du kannst wählen:', ...question!.answers], display: instruction);
  }
  Future<void> finish() async {
    if (!available || finished || saving ||
        (widget.game == 'memory' ? matched.length != cards.length : !canContinue || round != 4)) { return; }
    setState(() => saving = true);
    try {
      await widget.controller.completeGame(widget.game, childId: childId);
      if (mounted) {
        setState(() { finished = true; saving = false; });
        lessonScroll.jumpTo(0);
        coach([lessonWord('recap.${widget.game}'), lessonWord('finish.sticker')]);
        if (canSpeak) FluffAudio.instance.star();
      }
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        coach(['Dein Fortschritt konnte nicht gespeichert werden. Du kannst es noch einmal versuchen.']);
      }
    }
  }

  Widget gap() => const SizedBox(height: 12);
  Widget button(String label, VoidCallback? action, String key, {Color color = blue}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: GlossyButton(label,
      key: ValueKey(key), color: color, onPressed: action));
  Widget coachPanel() => GlossyPanel(child: Row(crossAxisAlignment: CrossAxisAlignment.start,
    children: [FluffSprite(pose: finished || canContinue ? 'proud' : 'explorer', size: 88,
      animate: widget.controller.data.motion), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Fluff hilft dir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(feedback.isEmpty ? instruction : feedback, style: const TextStyle(fontSize: 17)),
      ])),
    ]));

  List<Widget> memoryBoard() => [
    Text('${matched.length ~/ 2} von ${cards.length ~/ 2} Paaren gefunden',
      textAlign: TextAlign.center), gap(),
    GridView.count(crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12,
      crossAxisSpacing: 12, childAspectRatio: 1.4,
      children: [for (var i = 0; i < cards.length; i++)
        Semantics(button: true, label: 'Karte ${i + 1}'
          '${matched.contains(i) ? ', gefunden' : model.contains(i) || open.contains(i)
            ? ', ${lessonWord('memory.name.${cards[i]}')}' : ', verdeckt'}',
          child: InkWell(key: ValueKey('memory-card-$i'), borderRadius: BorderRadius.circular(22),
            onTap: () => chooseCard(i),
            child: Container(decoration: BoxDecoration(
              color: matched.contains(i) ? const Color(0xffd1f8de)
                : open.contains(i) || model.contains(i) ? Colors.white : const Color(0xffb6e4ff),
              borderRadius: BorderRadius.circular(22), border: Border.all(color: blue, width: 2)),
              child: Center(child: open.contains(i) || model.contains(i) || matched.contains(i)
                ? ArtIcon(['teddy','book','moon','game','tooth','bag'][cards[i]], size: 56)
                : const Icon(Icons.star_rounded, color: blue, size: 52))))),
      ]), gap(),
    if (mismatch || model.isNotEmpty) button(model.isNotEmpty ? 'Jetzt selbst suchen'
      : 'Zudecken und neu suchen', resetCards, 'memory-reset', color: green),
    if (!mismatch && model.isEmpty && matched.length != cards.length)
      button('Bilder kennenlernen', () => showMemoryModel(all: true), 'memory-explore'),
    if (matched.length == cards.length)
      button('Sticker sammeln', saving ? null : finish, 'memory-finish', color: green),
  ];

  List<Widget> practiceBoard() => [
    gap(), const Text('Jetzt probierst du es aus', textAlign: TextAlign.center,
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), gap(),
    GlossyPanel(child: Text('„${question!.practice!.phrase}“', textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), gap(),
    if (!phraseTried) ...[
      Text(lessonWord('practice.spoken'), textAlign: TextAlign.center), gap(),
      button('Ich habe den Satz ausprobiert', tryPhrase, 'try-phrase', color: green),
    ] else ...[
      Text(question!.practice!.prompt, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), gap(),
      for (var i = 0; i < question!.practice!.answers.length; i++)
        button(question!.practice!.answers[i], practiced ? null : () => choosePractice(i),
          'practice-answer-$i', color: practiced && i == 0 ? green : blue),
    ],
  ];

  List<Widget> feelingPractice() => [
    gap(), Text(lessonWord('feelings.support'), textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), gap(),
    for (final option in ['breathe', 'talk', 'pause'])
      button(lessonWord('support.$option'), () => chooseSupport(option), 'support-$option',
        color: support == option ? green : blue),
    if (support.isNotEmpty) ...[
      GlossyPanel(child: Text(lessonWord('$support.intro'), textAlign: TextAlign.center)), gap(),
      if (support == 'breathe') ...[
        Center(child: Icon(Icons.air_rounded, color: blue, size: breaths.isEven ? 72 : 96)),
        Text('${breaths ~/ 2} von 3 Atemzügen', textAlign: TextAlign.center), gap(),
        button(breaths.isEven ? 'Ich atme ein' : 'Ich atme aus',
          practiced ? null : breathe, 'breathe-step', color: green),
      ],
      if (support == 'talk') ...[
        for (var i = 0; i < 3; i++) button(lessonWord('talk.sentence.$i'),
          practiced ? null : () => selectSentence(i), 'talk-sentence-$i',
          color: talkSentence == i ? green : blue),
        if (talkSentence != null) button('Ich habe den Satz ausprobiert',
          practiced ? null : completeSupport, 'support-done', color: green),
      ],
      if (support == 'pause') ...[
        FluffSprite(pose: 'sleeping', size: 100, animate: false),
        button('Ich bin bereit', practiced ? null : completeSupport, 'support-done', color: green),
      ],
    ],
  ];

  List<Widget> questionBoard() => [
    Text('Entdeckung ${round + 1} von 5', textAlign: TextAlign.center), gap(),
    Text(question!.prompt, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), gap(),
    if (widget.game == 'count') CountingBoard(count: question!.symbols.length,
      progress: exploration!, enabled: !answered, onTouch: touch),
    if (widget.game == 'shapes') ShapeBoard(shape: question!.shape,
      progress: exploration!, enabled: !answered, onTouch: touch),
    if (widget.game == 'patterns') PatternBoard(question: question!, progress: exploration!,
      enabled: !answered, onTouch: touch, showGroups: showGroups),
    if (!needsExploration) Center(child: LearningSymbol(question!.visual, size: 68)),
    gap(),
    if (needsExploration && !answered) ...[
      Text(instruction, textAlign: TextAlign.center), gap(),
      if (!exploration!.ready) button(widget.game == 'count' ? 'Mit Fluff weiterzählen'
        : widget.game == 'shapes' ? 'Fluff zeigt den nächsten Punkt' : 'Mit Fluff die Gruppe ansehen',
        () => touch(exploration!.next, assisted: true), 'explore-next'),
      if (widget.game == 'count') TextButton(onPressed: countAgain,
        child: const Text('Noch einmal zählen')),
    ],
    if (!answered || needsExploration) ...[
      if (!canAnswer) const Text('Erst gemeinsam erkunden, dann auswählen.', textAlign: TextAlign.center),
      for (var i = 0; i < question!.answers.length; i++)
        widget.game == 'patterns' ? Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(button: true, label: symbolNames[question!.answers[i]],
            child: GlossyPanel(key: ValueKey('answer-$i'),
              color: answered && i == selectedAnswer ? const Color(0xffd1f8de)
                : const Color(0xffb6e4ff),
              onTap: answered || !canAnswer ? null : () => chooseAnswer(i),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                LearningSymbol(question!.answers[i], size: 36), const SizedBox(width: 12),
                Flexible(child: Text(symbolNames[question!.answers[i]]!,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              ]))))
        : button(question!.answers[i], answered || !canAnswer ? null : () => chooseAnswer(i),
            'answer-$i', color: answered && i == selectedAnswer ? green : blue),
    ],
    if (answered && question!.personalFeeling) ...[
      Text('Dein Gefühlswort: ${question!.answers[selectedAnswer!]}', textAlign: TextAlign.center),
      ...feelingPractice(),
    ],
    if (answered && question!.practice != null) ...practiceBoard(),
    if (canContinue) button(round == 4 ? 'Sticker sammeln' : 'Weiter',
      saving ? null : next, 'next-question', color: green),
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: widget.controller,
    builder: (context, _) => Scaffold(appBar: AppBar(title: Text(gameTitles[widget.game]!)),
      body: WorldBackground(child: SafeArea(child: ListView(
        controller: lessonScroll, padding: const EdgeInsets.fromLTRB(18, 12, 18, 28), children: [
          if (!available) const Text('Dieses Spiel wird für dein Kinderprofil im Elternbereich mit Fluff Pro geöffnet.')
          else if (!started) ...[
            FluffSprite(pose: 'explorer', size: 170, animate: widget.controller.data.motion),
            Text('Lerne mit Fluff', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall), gap(),
            GlossyPanel(child: Text(lessonWord('intro.${widget.game}'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 21))), gap(),
            const Text('Du darfst Hilfe holen, wiederholen und Pausen machen.',
              textAlign: TextAlign.center), gap(),
            button('Mit Fluff üben', start, 'start-learning', color: green),
            TextButton.icon(onPressed: canSpeak ? readPrompt : null,
              icon: const Icon(Icons.volume_up_rounded), label: const Text('Fluff anhören')),
          ] else if (finished) ...[
            FluffSprite(pose: 'proud', size: 170, animate: widget.controller.data.motion),
            const Text('Entdeckt!', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)), gap(),
            GlossyPanel(child: Text(lessonWord('recap.${widget.game}'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 21))), gap(),
            Text(lessonWord('finish.sticker'), textAlign: TextAlign.center), gap(),
            button('Noch einmal üben', () => Navigator.pushReplacement(context,
              MaterialPageRoute<void>(builder: (_) => LearningGamePage(
                controller: widget.controller, game: widget.game))), 'play-again'),
            button('Zur Entdeckerwelt', () => Navigator.pop(context), 'leave-game', color: green),
          ] else ...[
            coachPanel(),
            Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
              TextButton.icon(key: const ValueKey('lesson-help'), onPressed: saving ? null : help,
                icon: const Icon(Icons.emoji_objects_rounded), label: const Text('Fluff hilft mir')),
              TextButton.icon(onPressed: canSpeak ? readPrompt : null,
                icon: const Icon(Icons.volume_up_rounded), label: const Text('Nochmal hören')),
            ]), gap(),
            if (widget.game == 'memory') ...memoryBoard() else ...questionBoard(),
            if (saving) const Center(child: CircularProgressIndicator()),
          ],
          gap(), TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Ich mache eine Pause')),
        ])))));
}
