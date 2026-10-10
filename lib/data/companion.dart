import 'controller.dart';
import 'models.dart';

String starWord(int n) => n == 1 ? 'Stern' : 'Sterne';
List<String> balanceNarration(int n) => n == 1
  ? ['Du hast einen Stern in deinem Glas.']
  : ['Du hast', ...spokenNumber(n), 'Sterne in deinem Glas.'];
List<String> earnedNarration(int earned, int balance) => [
  if (earned == 1) 'Du bekommst einen Stern dazu.'
  else ...['Du bekommst', ...spokenNumber(earned), 'Sterne dazu.'],
  ...balanceNarration(balance),
  'Möchtest du noch etwas probieren oder eine Pause machen?',
];

/// Whole recordings for small numbers, with German hundred/thousand parts.
/// No ledger value is rounded to match the decorative jar.
List<String> spokenNumber(int value) {
  if (value < 0) return ['minus', ...spokenNumber(-value)];
  if (value <= 100) return ['$value'];
  if (value < 1000) return [
    '${value ~/ 100 == 1 ? 'ein' : _units[value ~/ 100]}hundert',
    if (value % 100 > 0) ...spokenNumber(value % 100),
  ];
  if (value < 1000000) return [
    if (value ~/ 1000 == 1) 'eintausend'
    else ...[...spokenNumber(value ~/ 1000), 'tausend'],
    if (value % 1000 > 0) ...spokenNumber(value % 1000),
  ];
  return ['$value']; // Rare larger parent-entered totals use local speech.
}
const _units = ['', 'ein', 'zwei', 'drei', 'vier', 'fünf', 'sechs',
  'sieben', 'acht', 'neun'];

class RewardExplanation {
  const RewardExplanation({required this.balance, required this.cost,
    required this.title});
  final int balance, cost;
  final String title;
  bool get affordable => balance >= cost;
  int get remaining => balance - cost;
  int get missing => affordable ? 0 : cost - balance;
  String get summary => affordable
    ? 'Du hast $balance ${starWord(balance)}. Dein Wunsch kostet $cost '
      '${starWord(cost)}. Nach dem Einlösen bleiben $remaining '
      '${starWord(remaining)} in deinem Glas.'
    : 'Du hast $balance ${starWord(balance)}. Dein Wunsch kostet $cost '
      '${starWord(cost)}. Dafür fehlen noch $missing ${starWord(missing)}.';
  List<String> get narration => [
    ...balanceNarration(balance),
    'Dein Wunsch heißt:', title,
    if (cost == 1) 'Dein Wunsch kostet einen Stern.'
    else ...['Dein Wunsch kostet', ...spokenNumber(cost), 'Sterne.'],
    if (affordable) ...[
      if (remaining == 1) 'Wenn dein Wunsch erfüllt wird, bleibt ein Stern übrig.'
      else ...['Wenn dein Wunsch erfüllt wird, bleiben',
        ...spokenNumber(remaining), 'Sterne übrig.'],
      'Wir fragen zuerst deine Erwachsenen. Erst wenn sie deinen Wunsch '
        'erfüllen, gehen die Sterne aus dem Glas.',
    ] else ...[
      if (missing == 1) 'Dafür fehlt noch ein Stern.'
      else ...['Dafür fehlen noch', ...spokenNumber(missing), 'Sterne.'],
      'Du darfst in deinem Tempo weitersammeln. Du musst nichts sofort schaffen.',
    ],
  ];
}

List<TaskItem> nextDayTasks(AppController c) {
  final day = c.dayTasks.where((task) => !c.done(task));
  final evening = c.eveningTasks.where((task) => !c.done(task));
  return c.now.hour >= 18 ? [...evening, ...day] : [...day, ...evening];
}

List<String> dayNarration(AppController c) {
  final tasks = [...c.dayTasks, ...c.eveningTasks];
  final finished = tasks.where((task) => c.done(task)).length;
  final next = nextDayTasks(c);
  final hour = c.now.hour;
  return [
    hour < 11 ? 'Guten Morgen!' : hour < 18 ? 'Hallo! Schön, dass du da bist!'
      : 'Guten Abend!',
    'Ich bin Fluff. Wir schauen zusammen auf deinen Tag.',
    if (tasks.isEmpty) 'Heute sind keine Aufgaben eingeplant. Zeit zum Spielen '
      'und Ausruhen.'
    else ...[
      if (tasks.length == 1) 'Heute ist eine kleine Aufgabe eingeplant.'
      else ...['Heute sind', ...spokenNumber(tasks.length), 'kleine Aufgaben eingeplant.'],
      if (finished == 1) 'Du hast schon eine Aufgabe geschafft. Hilfe bekommen '
        'zählt genauso.'
      else if (finished > 1) ...['Du hast schon', ...spokenNumber(finished),
        'Aufgaben geschafft. Hilfe bekommen zählt genauso.'],
      if (next.isNotEmpty) ...['Als Nächstes kannst du das ausprobieren:',
        next.first.title, 'Tippe auf das Bild. Ich erkläre dir einen Schritt '
          'nach dem anderen.']
      else 'Deine Aufgaben sind für heute geschafft. Du darfst eine Pause machen.',
    ],
    ...balanceNarration(c.balance()),
    ...lastRewardNarration(c),
    if (c.data.requests.any((r) => r.childId == c.child.id && r.status == 'offen'))
      'Ein Wunsch wartet auf deine Erwachsenen. Deine Sterne bleiben bis zum '
        'Einlösen im Glas.',
    'Was möchtest du machen? Deinen Tag anschauen, eine Geschichte hören '
      'oder zusammen winken?',
  ];
}

List<String> lastRewardNarration(AppController c) {
  final entries = c.data.stars.where((e) => e.childId == c.child.id).toList();
  final rewards = entries.where((e) => e.source == 'reward' && e.date == c.today && e.amount < 0);
  if (rewards.isEmpty) return [];
  final entry = rewards.last;
  var before = 0;
  for (final e in entries) {
    if (e.id == entry.id) break;
    before += e.amount;
  }
  final cost = -entry.amount;
  final after = before - cost;
  return ['Deine Erwachsenen haben deinen Wunsch erfüllt:', entry.label,
    'Vorher hattest du', ...spokenNumber(before), '${starWord(before)}.',
    if (cost == 1) 'Dafür wurde ein Stern eingelöst.'
    else ...['Dafür wurden', ...spokenNumber(cost), 'Sterne eingelöst.'],
    if (after == 1) 'Danach war noch ein Stern im Glas.'
    else ...['Danach waren noch', ...spokenNumber(after), 'Sterne im Glas.'],
  ];
}

List<String> childScreenNarration(AppController c, int tab) => switch (tab) {
  0 => dayNarration(c),
  1 => ['Hier sind deine Aufgaben für heute.',
    'Tippe auf ein Bild. Ich sage dir, was du tun kannst.',
    'Du darfst dir Hilfe holen. Gemeinsam schaffen zählt.',
    if (c.dayTasks.isEmpty) 'Heute sind keine Aufgaben eingeplant. Zeit zum '
      'Spielen und Ausruhen.'
    else ...['Deine Aufgaben heißen:', ...c.dayTasks.map((t) => t.title)],
  ],
  2 => ['Das ist dein Sternenglas.', ...balanceNarration(c.balance()),
    ...lastRewardNarration(c),
    'Tippe auf die Wunschkiste. Wir schauen, was ein Wunsch kostet und wie '
      'viele Sterne danach bleiben.',
    'Die Zahl unter dem Glas zeigt alle deine Sterne. Ein Stern mit einer '
      'Zahl ist ein Päckchen mit so vielen Sternen.'],
  3 => ['Wie fühlst du dich gerade?', 'Schau dir Fluffs Gesichter an.',
    'Glücklich. Traurig. Wütend. Unsicher. Müde. Stolz.',
    'Tippe auf das passende Gesicht. Jedes Gefühl darf da sein.'],
  _ => ['Hier kannst du mehr entdecken.', 'Lernspiele. Malen. Kleine Missionen. '
    'Deine Wünsche. Dein Abend. Dein Tagesplan. Und ruhig atmen.',
    'Tippe auf ein Bild. Ich zeige dir, wie es geht.'],
};

const fluffStories = <({String title, String icon, List<String> steps})>[
  (title: 'Mein Turm fällt um', icon: 'game', steps: [
    'Heute habe ich einen Turm gebaut. Plumps! Er ist umgefallen.',
    'Ich war traurig. Ich habe eine Pause gemacht.',
    'Dann habe ich es mit großen Klötzen unten noch einmal probiert.',
    'Mein Turm stand! Manches klappt noch nicht. Wir dürfen üben.',
    'Magst du mit mir winken? Oder später einen eigenen Turm bauen?',
  ]),
  (title: 'Ich frage nach Hilfe', icon: 'help', steps: [
    'Heute wollte ich meine Jacke zumachen. Der Reißverschluss klemmte.',
    'Ich habe gesagt: Kannst du mir bitte helfen?',
    'Zusammen ging es leichter. Hilfe holen ist mutig.',
    'Du darfst auch fragen: Hilfst du mir bitte?',
  ]),
  (title: 'Eins nach dem anderen', icon: 'gift', steps: [
    'Heute lagen meine Spielsachen überall. Das war mir zu viel.',
    'Ich habe erst einen Teddy in seine Kiste gelegt.',
    'Dann einen Ball. Eins nach dem anderen.',
    'Danach habe ich eine Pause gemacht. Kleine Schritte sind okay.',
  ]),
  (title: 'Mein Nein zählt', icon: 'heart', steps: [
    'Heute wollte ich keine Umarmung. Ich habe Nein gesagt.',
    'Mein Freund hat gefragt: Sollen wir lieber winken?',
    'Wir haben gewinkt. Das hat sich gut angefühlt.',
    'Dein Körper gehört dir. Du darfst Nein sagen und Hilfe holen.',
  ]),
  (title: 'Ich warte mit Fluff', icon: 'teddy', steps: [
    'Heute wollte ich mit dem roten Auto spielen. Mein Freund war dran.',
    'Ich habe gefragt: Darf ich danach dran sein?',
    'Beim Warten habe ich mir einen Ball ausgesucht.',
    'Später war ich dran. Wir können zusammen eine Lösung suchen.',
  ]),
  (title: 'Traurig sein ist okay', icon: 'heart', steps: [
    'Heute habe ich jemanden vermisst. Ich war traurig.',
    'Ich habe einer vertrauten Person davon erzählt.',
    'Sie ist bei mir geblieben. Ich musste nicht sofort fröhlich sein.',
    'Du darfst auch traurig sein. Hol dir jemanden, der dir zuhört.',
  ]),
  (title: 'Ein kleines Missgeschick', icon: 'bowl', steps: [
    'Heute ist mir Wasser umgekippt. Ups!',
    'Ich habe Bescheid gesagt und nach Hilfe gefragt.',
    'Zusammen haben wir das Wasser weggewischt.',
    'Fehler passieren. Wir können danach etwas tun.',
  ]),
];
