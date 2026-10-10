import 'dart:math';

const gameIds = ['memory', 'count', 'shapes', 'patterns', 'feelings', 'kindness'];
const gameTitles = {
  'memory': 'Paare finden', 'count': 'Sterne zählen',
  'shapes': 'Formen entdecken', 'patterns': 'Muster weiterdenken',
  'feelings': 'Gefühle verstehen', 'kindness': 'Gemeinsam handeln',
};
const gameDescriptions = {
  'memory': 'Zwei gleiche Bilder gehören zusammen.',
  'count': 'Zähle in deinem eigenen Tempo.',
  'shapes': 'Kreis, Dreieck, Quadrat und Stern entdecken.',
  'patterns': 'Was kommt als Nächstes?',
  'feelings': 'Alle Gefühle dürfen da sein.',
  'kindness': 'Kleine Situationen aus deinem Alltag.',
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

class LearningQuestion {
  const LearningQuestion(this.prompt, this.visual, this.answers,
      this.correct, this.explanation);
  final String prompt, visual, explanation;
  final List<String> answers;
  final int correct;
  List<String> get narration => [prompt, 'Du kannst wählen:',
    ...answers.map((answer) => symbolNames[answer] ?? answer)];
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
          List.filled(n, '⭐').join(' '),
          options.map((i) => '$i').toList(), options.indexOf(n),
          n == 1 ? 'Das ist 1 Stern. Du darfst jeden Stern einzeln zählen.'
            : 'Das sind $n Sterne. Du darfst jeden Stern einzeln zählen.');
      case 'shapes':
        const names = ['Kreis', 'Dreieck', 'Quadrat', 'Stern'];
        const visuals = ['●', '▲', '■', '★'];
        final index = random.nextInt(names.length);
        return LearningQuestion('Welche Form ist das?', visuals[index], names,
          index, '${names[index]} – jede Form sieht anders aus.');
      case 'patterns':
        const patterns = [
          ['🔵', '🟡'], ['⭐', '💙'], ['🌸', '🍀'], ['🟣', '🟢', '🟡'],
          ['🧸', '📘', '⭐'], ['🌙', '☀️', '🌈'],
        ];
        final p = patterns[random.nextInt(age < 6 ? 3 : patterns.length)];
        final length = p.length * 2;
        final next = p[length % p.length];
        final options = ['🔵', '🟡', '⭐', '💙', '🌸', '🍀', '🟣', '🟢',
          '🧸', '📘', '🌙', '☀️', '🌈']..remove(next)..shuffle(random);
        final answers = [next, ...options.take(2)]..shuffle(random);
        return LearningQuestion('Was kommt als Nächstes?',
          '${List.generate(length, (i) => p[i % p.length]).join(' ')}  ?',
          answers, answers.indexOf(next),
          'Das Muster beginnt wieder mit ${symbolNames[next]}.');
      case 'feelings':
        return feelingQuestions[random.nextInt(feelingQuestions.length)];
      case 'kindness':
        return kindnessQuestions[random.nextInt(kindnessQuestions.length)];
      default:
        throw ArgumentError.value(game, 'game');
    }
  }
}

const feelingQuestions = [
  LearningQuestion('Dein Turm fällt um. Wie könntest du dich fühlen?', '😢',
    ['Traurig', 'Hungrig', 'Ausgeschlafen'], 0,
    'Du darfst traurig sein. Wenn du magst, baust du später neu.'),
  LearningQuestion('Jemand nimmt dir ungefragt dein Spielzeug weg.', '😠',
    ['Wütend', 'Müde', 'Satt'], 0,
    'Wut ist okay. Sag: Ich möchte gefragt werden. Du musst niemanden hauen.'),
  LearningQuestion('Du hast lange gespielt und gähnst.', '🥱',
    ['Müde', 'Wütend', 'Erschrocken'], 0,
    'Dein Körper braucht eine Pause. Ruhe ist wichtig.'),
  LearningQuestion('Du schaffst etwas nach mehreren Versuchen.', '😊',
    ['Stolz', 'Durstig', 'Müde'], 0,
    'Du darfst stolz sein. Du hast es in deinem Tempo versucht.'),
  LearningQuestion('Heute ist alles neu. Du weißt noch nicht, was passiert.', '😟',
    ['Unsicher', 'Satt', 'Ausgeschlafen'], 0,
    'Unsicher sein ist okay. Frag eine vertraute Person, was als Nächstes kommt.'),
  LearningQuestion('Du freust dich auf ein Spiel mit deinem Freund.', '😄',
    ['Glücklich', 'Müde', 'Durstig'], 0,
    'Freude darfst du zeigen. Andere dürfen sich anders fühlen.'),
  LearningQuestion('Dein Freund ist traurig. Was hilft?', '💙',
    ['Fragen: Soll ich bei dir bleiben?', 'Sagen: Stell dich nicht so an.',
      'Sofort lachen.'], 0,
    'Du kannst zuhören. Dein Freund entscheidet, ob er Nähe möchte.'),
  LearningQuestion('Du bist wütend. Was kannst du tun?', '🌬️',
    ['Abstand nehmen und ruhig atmen.', 'Jemanden hauen.', 'Alles werfen.'], 0,
    'Du darfst wütend sein. Hände bleiben sicher. Hol Hilfe, wenn du sie brauchst.'),
];
const kindnessQuestions = [
  LearningQuestion('Du möchtest mit einem Spielzeug spielen, das jemand benutzt.', '🧸',
    ['Freundlich fragen und warten.', 'Es einfach wegnehmen.', 'Schubsen.'], 0,
    'Sag: Darf ich danach dran sein? Ein Nein darfst du auch hören.'),
  LearningQuestion('Du schaffst den Reißverschluss noch nicht.', '🧥',
    ['Um Hilfe bitten.', 'Dich selbst schimpfen.', 'Die Jacke wegwerfen.'], 0,
    'Sag: Kannst du mir bitte helfen? Hilfe holen ist mutig.'),
  LearningQuestion('Du hast aus Versehen Wasser verschüttet.', '💧',
    ['Bescheid sagen und zusammen aufwischen.', 'Jemand anderem die Schuld geben.',
      'So tun, als wäre nichts.'], 0,
    'Fehler passieren. Ein Erwachsener kann dir beim Aufwischen helfen.'),
  LearningQuestion('Du möchtest gerade keine Umarmung.', '✋',
    ['Nein sagen. Mein Körper gehört mir.', 'Du musst immer Ja sagen.',
      'Du darfst nie etwas sagen.'], 0,
    'Dein Nein zählt. Nähe soll sich für dich gut anfühlen.'),
  LearningQuestion('Dein Freund möchte nicht teilen.', '🧩',
    ['Nach einer gemeinsamen Lösung fragen.', 'Es ihm wegnehmen.', 'Ihn auslachen.'], 0,
    'Teilen darf freiwillig sein. Vielleicht könnt ihr abwechseln oder anders spielen.'),
  LearningQuestion('Du hast jemanden aus Versehen verletzt.', '💙',
    ['Entschuldigen und fragen, was hilft.', 'Darüber lachen.', 'Einfach weitergehen.'], 0,
    'Sag: Das tut mir leid. Brauchst du Hilfe? Hol einen Erwachsenen dazu.'),
  LearningQuestion('Du willst über eine Straße gehen.', '🚦',
    ['Mit einer erwachsenen Person gehen.', 'Einfach loslaufen.', 'Nur dem Ball folgen.'], 0,
    'An der Straße hältst du an. Geh mit einer vertrauten erwachsenen Person.'),
  LearningQuestion('Dir ist etwas unheimlich.', '🤝',
    ['Zu einer vertrauten Person gehen.', 'Du musst alles allein schaffen.',
      'Nichts erzählen.'], 0,
    'Du darfst Hilfe holen und erzählen, was dir Angst macht.'),
];
