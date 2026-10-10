import 'dart:math';
import 'learning_words.dart';
export 'learning_words.dart';

const gameIds = ['memory', 'count', 'shapes', 'patterns', 'feelings', 'kindness'];
const gameTitles = {
  'memory': 'Paare finden', 'count': 'Sterne zählen',
  'shapes': 'Formen entdecken', 'patterns': 'Muster weiterdenken',
  'feelings': 'Gefühle verstehen', 'kindness': 'Gemeinsam handeln',
};
const gameDescriptions = {
  'memory': 'Bilder und ihre Plätze mit Fluff merken.',
  'count': 'Sterne antippen, zählen und Mengen verstehen.',
  'shapes': 'Ecken, runde Linien und Spitzen erkunden.',
  'patterns': 'Gruppen entdecken und Muster fortsetzen.',
  'feelings': 'Gefühle benennen und kleine Hilfen ausprobieren.',
  'kindness': 'Freundliche Worte, Grenzen und Hilfe holen üben.',
};
const gameArtwork = {
  'memory': 'teddy', 'count': 'star', 'shapes': 'game',
  'patterns': 'book', 'feelings': 'heart', 'kindness': 'family',
};
const symbolNames = {
  '🔵': 'blauer Kreis', '🟡': 'gelber Kreis', '🟣': 'lila Kreis',
  '🟢': 'grüner Kreis', '⭐': 'Stern', '💙': 'Herz', '🌸': 'Blume',
  '🍀': 'Baum', '🧸': 'Teddybär', '📘': 'Buch', '🌙': 'Mond',
  '☀️': 'Sonne', '🌈': 'Regenbogen',
};
const patternUnits = [
  ['🔵', '🟡'], ['⭐', '💙'], ['🌸', '🍀'], ['🟣', '🟢', '🟡'],
  ['🧸', '📘', '⭐'], ['🌙', '☀️', '🌈'],
];
const feelingNames = ['Traurig', 'Wütend', 'Müde', 'Stolz', 'Unsicher',
  'Glücklich', 'Weiß ich noch nicht'];
const shapeIds = ['circle', 'triangle', 'square', 'star'];

class ActionPractice {
  const ActionPractice(this.phrase, this.prompt, this.answers, this.explanation);
  final String phrase, prompt, explanation;
  final List<String> answers;
  List<String> get narration => [prompt, 'Du kannst wählen:', ...answers];
}

class LearningQuestion {
  const LearningQuestion(this.prompt, this.visual, this.answers,
    this.correct, this.explanation, {this.id = '', this.personalFeeling = false,
    this.shape = '', this.unit = const [], this.practice});
  final String prompt, visual, explanation, id, shape;
  final List<String> answers, unit;
  final int correct;
  final bool personalFeeling;
  final ActionPractice? practice;
  bool accepts(int index) => index >= 0 && index < answers.length &&
    (personalFeeling || index == correct);
  List<String> get symbols => visual.trim().split(RegExp(r'\s+'))
    .where((s) => s != '?').toList();
  int get explorationSteps => shape.isNotEmpty ? switch (shape) {
    'circle' => 1, 'triangle' => 3, 'square' => 4, _ => 5,
  } : unit.isNotEmpty ? unit.length : symbols.length;
  List<String> get narration => [prompt, 'Du kannst wählen:',
    ...answers.map((answer) => symbolNames[answer] ?? answer)];
  LearningQuestion shuffled(Random random) {
    if (personalFeeling) return this;
    final order = List.generate(answers.length, (i) => i)..shuffle(random);
    return LearningQuestion(prompt, visual, order.map((i) => answers[i]).toList(),
      order.indexOf(correct), explanation, id: id, personalFeeling: personalFeeling,
      shape: shape, unit: unit, practice: practice);
  }
}

/// Scaffolding changes the next task, within the selected child's age range.
class LearningJourney {
  LearningJourney(this.age);
  final int age;
  int independent = 0;
  bool supported = false;
  final seen = <String>{};
  int get challengeAge => independent >= 4 && age >= 7 ? age
    : independent >= 2 && age >= 5 ? age.clamp(5, 6) : age.clamp(2, 4);
  void help() { supported = true; independent = 0; }
  void complete() {
    if (!supported) independent++;
    supported = false;
  }
  LearningQuestion next(GameFactory factory, String game) {
    LearningQuestion q = factory.question(game, challengeAge);
    for (var attempt = 0; attempt < 24 && seen.contains(q.id.isEmpty ? q.prompt + q.visual : q.id); attempt++) {
      q = factory.question(game, challengeAge);
    }
    seen.add(q.id.isEmpty ? q.prompt + q.visual : q.id);
    return q.shuffled(factory.random);
  }
}

/// Touching an item again never advances counting or awards extra progress.
class ExplorationProgress {
  ExplorationProgress(this.requiredSteps, {this.ordered = false});
  final int requiredSteps;
  final bool ordered;
  final visited = <int>[];
  bool get ready => visited.length == requiredSteps;
  int get next => List.generate(requiredSteps, (i) => i)
    .firstWhere((i) => !visited.contains(i), orElse: () => -1);
  bool touch(int index) {
    if (index < 0 || index >= requiredSteps || visited.contains(index) ||
        (ordered && index != next)) { return false; }
    visited.add(index);
    return true;
  }
  int numberAt(int index) => visited.indexOf(index) + 1;
}

class GameFactory {
  GameFactory({Random? random}) : random = random ?? Random();
  final Random random;
  List<int> memoryCards(int age) {
    final pairs = age < 5 ? 2 : age < 7 ? 3 : 4;
    final values = List.generate(6, (i) => i)..shuffle(random);
    return [for (final v in values.take(pairs)) ...[v, v]]..shuffle(random);
  }
  LearningQuestion question(String game, int age) {
    switch (game) {
      case 'count':
        final max = age < 5 ? 4 : age < 7 ? 6 : 9;
        final n = 1 + random.nextInt(max);
        final choices = {n};
        while (choices.length < 3) { choices.add(1 + random.nextInt(max)); }
        final options = choices.toList()..shuffle(random);
        return LearningQuestion('Wie viele Sterne siehst du?',
          List.filled(n, '⭐').join(' '), options.map((i) => '$i').toList(),
          options.indexOf(n), lessonWord('count.total'), id: 'count-$n');
      case 'shapes':
        const names = ['Kreis', 'Dreieck', 'Quadrat', 'Stern'];
        const visuals = ['●', '▲', '■', '★'];
        final i = random.nextInt(names.length);
        return LearningQuestion('Welche Form ist das?', visuals[i], names, i,
          lessonWord('shape.${shapeIds[i]}.fact'), id: 'shape-$i', shape: shapeIds[i]);
      case 'patterns':
        final i = random.nextInt(age < 6 ? 3 : patternUnits.length);
        final p = patternUnits[i];
        final phase = random.nextInt(p.length);
        final length = p.length * 2 + phase;
        final next = p[phase];
        final options = symbolNames.keys.toList()..remove(next)..shuffle(random);
        final answers = [next, ...options.take(2)]..shuffle(random);
        return LearningQuestion('Was kommt als Nächstes?',
          '${List.generate(length, (j) => p[j % p.length]).join(' ')} ?',
          answers, answers.indexOf(next), lessonWord('pattern.$i.$phase.fact'),
          id: 'pattern-$i-$phase', unit: p);
      case 'feelings':
        return feelingQuestions[random.nextInt(feelingQuestions.length)];
      case 'kindness':
        return kindnessQuestions[random.nextInt(kindnessQuestions.length)];
      default:
        throw ArgumentError.value(game, 'game');
    }
  }
}

final feelingQuestions = List.generate(6, (i) => LearningQuestion(
  lessonWord('feeling.story.$i'), '💙', feelingNames, 0,
  lessonWord('feelings.explanation'), id: 'feeling-$i', personalFeeling: true));
final kindnessQuestions = List.generate(10, (i) => LearningQuestion(
  lessonWord('action.$i.prompt'),
  const ['🧸','🧥','💧','✋','🧩','💙','🚦','🤝','💙','🌬️'][i],
  List.generate(3, (j) => lessonWord('action.$i.answer.$j')), 0,
  lessonWord('action.$i.explanation'), id: 'action-$i', practice: ActionPractice(
    lessonWord('action.$i.phrase'), lessonWord('action.$i.follow'),
    List.generate(2, (j) => lessonWord('action.$i.response.$j')),
    lessonWord('action.$i.result'))));
