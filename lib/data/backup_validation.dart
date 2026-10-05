import 'dart:convert';
import 'models.dart';

const artIcons = {
  'tooth',
  'shirt',
  'bowl',
  'bag',
  'gift',
  'book',
  'cutlery',
  'teddy',
  'bed',
  'cinema',
  'game',
  'icecream',
  'moon',
  'zoo',
  'clipboard',
  'calendar',
};
const feelingValues = {
  'glücklich',
  'traurig',
  'wütend',
  'unsicher',
  'müde',
  'stolz',
};
const taskSkills = {'alltag', 'hilfe', 'lesen', 'dranbleiben'};
const taskRoutines = {'Tag', 'Morgen', 'Nachmittag', 'Abend'};

bool validTime(String value) =>
    RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
bool validTitle(String value) =>
    value.trim().isNotEmpty && value.trim().length <= 120;
bool _validDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null && dateKey(parsed) == value;
}

Never _invalid() => throw const FormatException(
  'Die Sicherung enthält ungültige oder unvollständige Daten.',
);

AppData parseBackup(String text) {
  try {
    final root = jsonDecode(text);
    if (root is! Map || root['app'] != 'Fluffs Sternenwelt') _invalid();
    final state = AppData.fromJson(Map<String, dynamic>.from(root['backup']));
    _validate(state);
    return state;
  } on FormatException {
    rethrow;
  } on TypeError {
    _invalid();
  } on ArgumentError {
    _invalid();
  }
}

void _validate(AppData d) {
  Set<String> ids(Iterable<String> values) {
    final list = values.toList();
    if (list.any((id) => !RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(id)) ||
        list.toSet().length != list.length) {
      _invalid();
    }
    return list.toSet();
  }

  final children = ids(d.children.map((x) => x.id));
  final tasks = ids(d.tasks.map((x) => x.id));
  final rewards = ids(d.rewards.map((x) => x.id));
  final plans = ids(d.plans.map((x) => x.id));
  final requests = ids(d.requests.map((x) => x.id));
  if (children.isEmpty ||
      !children.contains(d.selectedId) ||
      !RegExp(r'^[a-f0-9]{64}$').hasMatch(d.pinHash) ||
      !RegExp(r'^[a-f0-9]{48}$').hasMatch(d.salt) ||
      d.sequence < 0) {
    _invalid();
  }
  for (final c in d.children) {
    if (c.name.trim().isEmpty ||
        c.name.trim().length > 36 ||
        c.age < 2 ||
        c.age > 18 ||
        c.avatar < 0 ||
        c.avatar > 2 ||
        !_validDate(c.createdAt)) {
      _invalid();
    }
  }
  for (final t in d.tasks) {
    if (!validTitle(t.title) ||
        !validTime(t.time) ||
        !artIcons.contains(t.icon) ||
        !taskRoutines.contains(t.routine) ||
        !taskSkills.contains(t.skill) ||
        t.stars < 1 ||
        t.stars > 5 ||
        t.days.isEmpty ||
        t.days.any((day) => day < 1 || day > 7) ||
        t.days.toSet().length != t.days.length ||
        t.children.any((id) => !children.contains(id)) ||
        t.children.toSet().length != t.children.length ||
        t.steps.any((step) => step.trim().isEmpty || step.length > 1000)) {
      _invalid();
    }
  }
  for (final r in d.rewards) {
    if (!validTitle(r.title) ||
        !artIcons.contains(r.icon) ||
        r.cost < 1 ||
        r.cost > 999) {
      _invalid();
    }
  }
  for (final p in d.plans) {
    if (!validTitle(p.title) ||
        !validTime(p.time) ||
        !artIcons.contains(p.icon)) {
      _invalid();
    }
  }
  final moods = <String>{};
  for (final f in d.feelings) {
    if (!children.contains(f.childId) ||
        !_validDate(f.date) ||
        !feelingValues.contains(f.value) ||
        !moods.add('${f.childId}|${f.date}')) {
      _invalid();
    }
  }
  final pending = <String>{};
  for (final r in d.requests) {
    if (!children.contains(r.childId) ||
        !rewards.contains(r.rewardId) ||
        !validTitle(r.title) ||
        !_validDate(r.date) ||
        r.cost < 1 ||
        r.cost > 999 ||
        !{
          'offen',
          'erfüllt',
          'abgelehnt',
          'zurückgezogen',
        }.contains(r.status)) {
      _invalid();
    }
    if (r.status == 'offen' && !pending.add('${r.childId}|${r.rewardId}')) {
      _invalid();
    }
  }
  final starIds = <String>{};
  final balances = {for (final id in children) id: 0};
  for (final e in d.stars) {
    if (!starIds.add(e.id) ||
        !children.contains(e.childId) ||
        !_validDate(e.date) ||
        !validTitle(e.label) ||
        !{'alltag', 'hilfe', 'lesen', 'mut', 'dranbleiben'}.contains(e.type) ||
        !taskSkills.contains(e.skill)) {
      _invalid();
    }
    switch (e.source) {
      case 'task':
        if (!tasks.contains(e.sourceId) ||
            e.amount < 1 ||
            e.amount > 5 ||
            e.id != '${e.childId}|${e.sourceId}|${e.date}') {
          _invalid();
        }
      case 'mission':
        final amount = {'helper': 3, 'reading': 5, 'courage': 2}[e.sourceId];
        final day = e.sourceId == 'reading'
            ? dateKey(monday(DateTime.parse(e.date)))
            : e.date;
        if (amount == null ||
            e.amount != amount ||
            e.id != '${e.childId}|mission|${e.sourceId}|$day') {
          _invalid();
        }
      case 'reward':
        if (!rewards.contains(e.sourceId) ||
            e.amount >= 0 ||
            e.amount < -999 ||
            !e.id.startsWith('reward|') ||
            !requests.contains(e.id.substring(7))) {
          _invalid();
        }
        final wish = d.requests.firstWhere((r) => r.id == e.id.substring(7));
        if (wish.status != 'erfüllt' ||
            wish.childId != e.childId ||
            wish.rewardId != e.sourceId ||
            e.amount != -wish.cost) {
          _invalid();
        }
      default:
        _invalid();
    }
    balances[e.childId] = balances[e.childId]! + e.amount;
  }
  if (balances.values.any((value) => value < 0)) _invalid();
  for (final r in d.requests.where((r) => r.status == 'erfüllt')) {
    if (!starIds.contains('reward|${r.id}')) _invalid();
  }
  for (final check in d.planChecks) {
    final parts = check.split('|');
    if (parts.length != 3 ||
        !children.contains(parts[0]) ||
        !plans.contains(parts[1]) ||
        !_validDate(parts[2])) {
      _invalid();
    }
  }
  for (final entry in d.dailyPlans.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 2 ||
        !children.contains(parts[0]) ||
        !_validDate(parts[1]) ||
        entry.value.any((id) => !tasks.contains(id)) ||
        entry.value.toSet().length != entry.value.length) {
      _invalid();
    }
  }
  for (final id in {...children, ...tasks, ...rewards, ...plans, ...requests}) {
    final match = RegExp(r'^[ctprw](\d+)$').firstMatch(id);
    if (match != null) {
      final value = int.parse(match.group(1)!);
      if (d.sequence < value) d.sequence = value;
    }
  }
}
