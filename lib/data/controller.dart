import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'repository.dart';
import 'backup_validation.dart';
import 'creative.dart';
import 'discovery.dart';
import '../services/pro_license.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository, {DateTime Function()? clock,
    ProLicenseVerifier? licenses})
    : clock = clock ?? DateTime.now,
      licenses = licenses ?? const ProLicenseVerifier();
  final ProLicenseVerifier licenses;
  bool _proActive = false;
  bool get proActive => _proActive;
  final StateRepository repository;
  final DateTime Function() clock;
  AppData data = AppData();
  bool loading = true, busy = false;
  String? error;
  int _pinFailures = 0;
  DateTime? _pinBlockedUntil;
  int tab = 0;
  bool externalFilePicker = false;
  void selectTab(int value) {
    tab = value;
    notifyListeners();
  }

  DateTime get now => clock();
  String get today => dateKey(now);
  ChildProfile get child => data.children.firstWhere(
    (x) => x.id == data.selectedId,
    orElse: () => data.children.first,
  );
  Future<void> init() async {
    try {
      data = await repository.load() ?? AppData();
      _proActive = await licenses.verify(data.proLicense);
      if (data.children.isNotEmpty && _recordToday(data)) {
        await repository.save(data);
      }
      error = null;
    } catch (_) {
      error = 'Die gespeicherten Daten konnten nicht geladen werden.';
    }
    loading = false;
    notifyListeners();
  }

  Future<T> _change<T>(T Function(AppData) update) async {
    if (busy) throw StateError('Bitte warte kurz.');
    busy = true;
    notifyListeners();
    try {
      final copy = data.copy();
      final result = update(copy);
      _recordToday(copy, updateExisting: true);
      await repository.save(copy);
      data = copy;
      error = null;
      return result;
    } catch (_) {
      error =
          'Die Änderung konnte nicht gespeichert werden. Deine Daten bleiben erhalten.';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
  void _setPin(AppData d, String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const FormatException('Die Eltern-PIN braucht vier Ziffern.');
    }
    d.salt = List.generate(
      24,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    d.pinHash = _hash(pin, d.salt);
  }

  bool verifyPin(String pin) {
    if (_pinBlockedUntil != null && now.isBefore(_pinBlockedUntil!)) {
      return false;
    }
    if (_hash(pin, data.salt) == data.pinHash) {
      _pinFailures = 0;
      _pinBlockedUntil = null;
      return true;
    }
    _pinFailures++;
    if (_pinFailures >= 5) {
      _pinFailures = 0;
      _pinBlockedUntil = now.add(const Duration(seconds: 30));
    }
    return false;
  }

  int get pinWait =>
      _pinBlockedUntil == null || !now.isBefore(_pinBlockedUntil!)
      ? 0
      : (_pinBlockedUntil!.difference(now).inMilliseconds / 1000).ceil();
  Future<void> changePin(String pin) => _change((d) => _setPin(d, pin));
  Future<void> setup(String name, int age, int avatar, String pin) =>
      _change((d) {
        if (d.children.isNotEmpty) {
          throw StateError('Die App ist bereits eingerichtet.');
        }
        _checkProfile(age, avatar);
        _setPin(d, pin);
        _seed(d);
        d.children.add(
          ChildProfile(
            id: d.nextId('c'),
            name: _name(name),
            age: age,
            avatar: avatar,
            createdAt: today,
          ),
        );
        d.selectedId = d.children.first.id;
      });
  String _name(String v) {
    if (v.trim().isEmpty || v.trim().length > 36) {
      throw const FormatException(
        'Bitte gib einen Namen mit 1 bis 36 Zeichen ein.',
      );
    }
    return v.trim();
  }

  Future<void> addChild(String name, int age, int avatar) => _change((d) {
    _checkProfile(age, avatar);
    d.children.add(
      ChildProfile(
        id: d.nextId('c'),
        name: _name(name),
        age: age,
        avatar: avatar,
        createdAt: today,
      ),
    );
  });
  Future<void> editChild(String id, String name, int age, int avatar) =>
      _change((d) {
        _checkProfile(age, avatar);
        final c = d.children.firstWhere((x) => x.id == id);
        c.name = _name(name);
        c.age = age;
        c.avatar = avatar;
      });
  Future<void> selectChild(String id) => _change((d) {
    if (!d.children.any((x) => x.id == id)) {
      throw StateError('Dieses Profil existiert nicht.');
    }
    d.selectedId = id;
  });
  Future<void> removeChild(String id) => _change((d) {
    if (d.children.length < 2) {
      throw StateError('Mindestens ein Kinderprofil bleibt bestehen.');
    }
    d.children.removeWhere((x) => x.id == id);
    d.stars.removeWhere((x) => x.childId == id);
    d.feelings.removeWhere((x) => x.childId == id);
    d.requests.removeWhere((x) => x.childId == id);
    d.planChecks.removeWhere((x) => x.startsWith('$id|'));
    d.dailyPlans.removeWhere((k, v) => k.startsWith('$id|'));
    d.gameWins.removeWhere((k, v) => k.startsWith('$id|'));
    d.drawings.removeWhere((x) => x.childId == id);
    for (final t in d.tasks) {
      if (t.children.contains(id)) {
        t.children.remove(id);
        if (t.children.isEmpty) t.active = false;
      }
    }
    if (d.selectedId == id) d.selectedId = d.children.first.id;
  });
  int balance([String? id, AppData? state]) => (state ?? data).stars
      .where((x) => x.childId == (id ?? child.id))
      .fold(0, (sum, x) => sum + x.amount);
  List<TaskItem> tasksOn(
    DateTime date, {
    String? childId,
    bool evening = false,
  }) => data.tasks
      .where(
        (t) =>
            t.active &&
            (t.children.isEmpty || t.children.contains(childId ?? child.id)) &&
            t.days.contains(date.weekday) &&
            ((t.routine == 'Abend') == evening),
      )
      .toList();
  List<TaskItem> get dayTasks => tasksOn(now);
  List<TaskItem> get eveningTasks => tasksOn(now, evening: true);
  String taskKey(String childId, String taskId, String date) =>
      '$childId|$taskId|$date';
  bool done(TaskItem task, {String? childId, String? date, AppData? state}) =>
      (state ?? data).stars.any(
        (e) => e.id == taskKey(childId ?? child.id, task.id, date ?? today),
      );
  int get completed => dayTasks.where((t) => done(t)).length;
  Future<bool> completeTask(TaskItem task, {bool assisted = false}) =>
      _change((d) {
        final t = d.tasks.firstWhere((x) => x.id == task.id);
        if (!dayTasks.any((x) => x.id == t.id) &&
            !eveningTasks.any((x) => x.id == t.id)) {
          throw StateError('Diese Aufgabe ist heute nicht eingeplant.');
        }
        final id = taskKey(d.selectedId, t.id, today);
        if (d.stars.any((e) => e.id == id)) return false;
        d.stars.add(
          StarEntry(
            id: id,
            childId: d.selectedId,
            source: 'task',
            sourceId: t.id,
            date: today,
            label: t.title,
            amount: t.stars,
            type: assisted ? 'mut' : t.skill,
            skill: t.skill,
            assisted: assisted,
          ),
        );
        return true;
      });
  List<StarEntry> _tasks(AppData d, String id) => d.stars
      .where((x) => x.childId == id && x.source == 'task' && x.amount > 0)
      .toList();
  int missionProgress(String key, {AppData? state, String? childId}) {
    final d = state ?? data;
    final events = _tasks(d, childId ?? child.id);
    if (key == 'helper') {
      return events.where((e) => e.date == today && e.skill == 'hilfe').length;
    }
    if (key == 'reading') {
      final start = dateKey(monday(now));
      final end = dateKey(addDays(monday(now), 7));
      return events
          .where(
            (e) =>
                e.date.compareTo(start) >= 0 &&
                e.date.compareTo(end) < 0 &&
                e.skill == 'lesen',
          )
          .map((e) => e.date)
          .toSet()
          .length;
    }
    return events.where((e) => e.date == today && e.assisted).length;
  }

  int missionTarget(String key) => key == 'courage' ? 1 : 3;
  int missionStars(String key) => key == 'reading'
      ? 5
      : key == 'helper'
      ? 3
      : 2;
  String missionLabel(String key) => key == 'reading'
      ? 'Lese-Champion'
      : key == 'helper'
      ? 'Heute: Ein guter Helfer'
      : 'Um Hilfe bitten ist mutig';
  String missionId(String key) =>
      '${child.id}|mission|$key|${key == 'reading' ? dateKey(monday(now)) : today}';
  bool missionClaimed(String key, {AppData? state}) =>
      (state ?? data).stars.any((e) => e.id == missionId(key));
  Future<void> claimMission(String key) => _change((d) {
    if (!['helper', 'reading', 'courage'].contains(key)) {
      throw const FormatException('Unbekannte Mission.');
    }
    if (missionProgress(key, state: d) < missionTarget(key)) {
      throw StateError('Für diesen Bonus fehlen noch kleine Schritte.');
    }
    if (missionClaimed(key, state: d)) return;
    d.stars.add(
      StarEntry(
        id: missionId(key),
        childId: d.selectedId,
        source: 'mission',
        sourceId: key,
        date: today,
        label: missionLabel(key),
        amount: missionStars(key),
        type: key == 'courage'
            ? 'mut'
            : key == 'helper'
            ? 'hilfe'
            : 'dranbleiben',
      ),
    );
  });
  Future<void> undoTask(TaskItem task) => _change((d) {
    final key = taskKey(d.selectedId, task.id, today);
    final prior = balance(d.selectedId, d);
    d.stars.removeWhere((e) => e.id == key);
    for (final mission in ['helper', 'reading', 'courage']) {
      if (missionProgress(mission, state: d) < missionTarget(mission)) {
        d.stars.removeWhere((e) => e.id == missionId(mission));
      }
    }
    if (balance(d.selectedId, d) < 0) {
      throw StateError(
        'Die Sterne sind bereits für einen Wunsch verwendet. Die Aufgabe kann nicht zurückgenommen werden.',
      );
    }
    if (prior == balance(d.selectedId, d)) {
      throw StateError('Diese Aufgabe wurde heute noch nicht erledigt.');
    }
  });
  Future<void> setFeeling(String value) => _change((d) {
    if (![
      'glücklich',
      'traurig',
      'wütend',
      'unsicher',
      'müde',
      'stolz',
    ].contains(value)) {
      throw const FormatException('Unbekanntes Gefühl.');
    }
    d.feelings.removeWhere((x) => x.childId == d.selectedId && x.date == today);
    d.feelings.add(Feeling(childId: d.selectedId, date: today, value: value));
  });
  String? get currentFeeling {
    final values = data.feelings.where(
      (x) => x.childId == child.id && x.date == today,
    );
    return values.isEmpty ? null : values.last.value;
  }

  Future<void> requestReward(RewardItem reward) => _change((d) {
    reward = d.rewards.firstWhere(
      (x) => x.id == reward.id,
      orElse: () => throw StateError('Dieser Wunsch ist nicht mehr verfügbar.'),
    );
    if (!reward.active) {
      throw StateError('Dieser Wunsch ist gerade nicht verfügbar.');
    }
    if (d.requests.any(
      (x) =>
          x.childId == d.selectedId &&
          x.rewardId == reward.id &&
          x.status == 'offen',
    )) {
      return;
    }
    if (balance(d.selectedId, d) < reward.cost) {
      throw StateError(
        'Sammle noch ${reward.cost - balance(d.selectedId, d)} Sterne.',
      );
    }
    d.requests.add(
      WishRequest(
        id: d.nextId('w'),
        childId: d.selectedId,
        rewardId: reward.id,
        title: reward.title,
        cost: reward.cost,
        date: today,
      ),
    );
  });
  Future<void> decideRequest(String id, String status) => _change((d) {
    final r = d.requests.firstWhere((x) => x.id == id);
    if (r.status != 'offen') return;
    if (!['erfüllt', 'abgelehnt', 'zurückgezogen'].contains(status)) {
      throw StateError('Ungültige Entscheidung.');
    }
    if (status == 'erfüllt') {
      if (balance(r.childId, d) < r.cost) {
        throw StateError('Für diesen Wunsch reichen die Sterne gerade nicht.');
      }
      d.stars.add(
        StarEntry(
          id: 'reward|${r.id}',
          childId: r.childId,
          source: 'reward',
          sourceId: r.rewardId,
          date: today,
          label: r.title,
          amount: -r.cost,
        ),
      );
    }
    r.status = status;
  });
  Future<void> saveTask(TaskItem task) => _change((d) {
    if (!validTitle(task.title) ||
        !artIcons.contains(task.icon) ||
        !taskSkills.contains(task.skill) ||
        !taskRoutines.contains(task.routine) ||
        task.days.any((day) => day < 1 || day > 7) ||
        task.days.toSet().length != task.days.length ||
        task.children.toSet().length != task.children.length ||
        task.steps.isEmpty ||
        task.steps.any((step) => step.trim().isEmpty || step.length > 1000) ||
        task.children.any((id) => !d.children.any((c) => c.id == id)) ||
        task.stars < 1 ||
        task.stars > 5 ||
        task.days.isEmpty ||
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(task.time)) {
      throw const FormatException(
        'Bitte überprüfe Name, Uhrzeit, Wochentage und Sterne.',
      );
    }
    final index = d.tasks.indexWhere((x) => x.id == task.id);
    if (index < 0) {
      task.id = d.nextId('t');
      d.tasks.add(TaskItem.fromJson(task.toJson()));
    } else {
      d.tasks[index] = TaskItem.fromJson(task.toJson());
    }
  });
  Future<void> saveReward(RewardItem reward) => _change((d) {
    if (!validTitle(reward.title) ||
        !artIcons.contains(reward.icon) ||
        reward.cost < 1 ||
        reward.cost > 999) {
      throw const FormatException(
        'Bitte gib einen Namen und 1 bis 999 Sterne ein.',
      );
    }
    final i = d.rewards.indexWhere((x) => x.id == reward.id);
    if (i < 0) {
      reward.id = d.nextId('r');
      d.rewards.add(RewardItem.fromJson(reward.toJson()));
    } else {
      d.rewards[i] = RewardItem.fromJson(reward.toJson());
    }
  });
  Future<void> savePlan(PlanItem plan) => _change((d) {
    if (!validTitle(plan.title) ||
        !artIcons.contains(plan.icon) ||
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(plan.time)) {
      throw const FormatException('Bitte überprüfe Name und Uhrzeit.');
    }
    final i = d.plans.indexWhere((x) => x.id == plan.id);
    if (i < 0) {
      plan.id = d.nextId('p');
      d.plans.add(PlanItem.fromJson(plan.toJson()));
    } else {
      d.plans[i] = PlanItem.fromJson(plan.toJson());
    }
  });
  bool planDone(PlanItem p, DateTime date) =>
      data.planChecks.contains('${child.id}|${p.id}|${dateKey(date)}');
  Future<void> togglePlan(PlanItem p) => _change((d) {
    final key = '${d.selectedId}|${p.id}|$today';
    if (!d.planChecks.remove(key)) d.planChecks.add(key);
  });
  Future<void> settings({bool? motion, bool? sound, bool? haptics}) =>
      _change((d) {
        d.motion = motion ?? d.motion;
        d.sound = sound ?? d.sound;
        d.haptics = haptics ?? d.haptics;
      });
  String exportBackup() => const JsonEncoder.withIndent(
    '  ',
  ).convert({'app': 'Fluffs Sternenwelt', 'backup': data.toJson()});
  Future<void> activatePro(String code) async {
    if (!await licenses.verify(code)) {
      throw const FormatException('Der Pro-Code ist ungültig. Bitte prüfe ihn.');
    }
    await _change((d) => d.proLicense = code.replaceAll(RegExp(r'\s'), ''));
    _proActive = true;
    notifyListeners();
  }
  int gameCount(String id, {String? childId}) =>
      data.gameWins['${childId ?? child.id}|$id'] ?? 0;
  Future<void> completeGame(String id, {required String childId}) => _change((d) {
    if (!proActive || !gameIds.contains(id) ||
        !d.children.any((c) => c.id == childId)) {
      throw StateError('Dieses Spiel ist aktuell nicht verfügbar.');
    }
    final key = '$childId|$id';
    d.gameWins[key] = min((d.gameWins[key] ?? 0) + 1, 100000);
  });
  List<SavedDrawing> get childDrawings =>
      data.drawings.where((d) => d.childId == child.id).toList().reversed.toList();
  Future<void> saveDrawing(int template, List<DrawStroke> strokes,
      {String? drawingId, required String childId}) => _change((d) {
    if (!d.children.any((c) => c.id == childId) ||
        template < 0 || template > 12 || (template > 0 && !proActive)) {
      throw StateError('Dieses Malbild ist aktuell nicht verfügbar.');
    }
    if (strokes.length > 400 || strokes.any((s) => s.points.length > 3000)) {
      throw StateError('Dein Bild ist sehr groß. Speichere eine kleinere Zeichnung.');
    }
    final id = drawingId ?? d.nextId('drawing');
    d.drawings.removeWhere((x) => x.id == id && x.childId == childId);
    final previous = d.drawings.where((x) => x.childId == childId).toList();
    if (previous.length >= 12) {
      throw StateError('Dein Album ist voll. Lösche zuerst ein älteres Bild.');
    }
    d.drawings.add(SavedDrawing(id: id, childId: childId, template: template,
      createdAt: today, strokes: strokes.map((s) =>
        DrawStroke.fromJson(s.toJson())).toList()));
  });
  Future<void> deleteDrawing(String id) => _change((d) {
    d.drawings.removeWhere((x) => x.id == id && x.childId == d.selectedId);
  });
  Future<void> restoreBackup(String text) async {
    if (busy) throw StateError('Bitte warte kurz.');
    final restored = parseBackup(text);
    final restoredPro = await licenses.verify(restored.proLicense);
    _recordToday(restored, updateExisting: true);
    busy = true;
    notifyListeners();
    try {
      await repository.save(restored);
      data = restored;
      _proActive = restoredPro;
      _pinBlockedUntil = null;
      _pinFailures = 0;
      error = null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _checkProfile(int age, int avatar) {
    if (age < 2 || age > 18 || avatar < 0 || avatar > 2) {
      throw const FormatException('Bitte überprüfe Alter und Profilbild.');
    }
  }

  bool _recordToday(AppData state, {bool updateExisting = false}) {
    var changed = false;
    for (final profile in state.children) {
      final key = '${profile.id}|$today';
      if (!updateExisting && state.dailyPlans.containsKey(key)) continue;
      final tasks = state.tasks
          .where(
            (t) =>
                t.active &&
                t.days.contains(now.weekday) &&
                (t.children.isEmpty || t.children.contains(profile.id)),
          )
          .map((t) => t.id)
          .toSet();
      // Erledigte Aufgaben bleiben Teil des damaligen Plans, auch wenn sie später deaktiviert werden.
      tasks.addAll(
        state.stars
            .where(
              (e) =>
                  e.childId == profile.id &&
                  e.source == 'task' &&
                  e.date == today,
            )
            .map((e) => e.sourceId),
      );
      final previous = state.dailyPlans[key];
      if (previous == null || !setEquals(previous.toSet(), tasks)) {
        state.dailyPlans[key] = tasks.toList();
        changed = true;
      }
    }
    return changed;
  }

  Future<void> refresh() async {
    if (!busy &&
        data.children.isNotEmpty &&
        !data.dailyPlans.containsKey('${child.id}|$today')) {
      try {
        await _change((_) {});
      } catch (_) {
        /* Der bisherige Stand bleibt erhalten. */
      }
    }
    notifyListeners();
  }

  int earnedSince(DateTime from, {DateTime? until, String? childId}) => data
      .stars
      .where(
        (x) =>
            x.childId == (childId ?? child.id) &&
            x.amount > 0 &&
            x.date.compareTo(dateKey(from)) >= 0 &&
            (until == null || x.date.compareTo(dateKey(until)) < 0),
      )
      .fold(0, (v, e) => v + e.amount);
  void _seed(AppData d) {
    void t(
      String title,
      String icon,
      String time,
      List<String> steps, {
      String routine = 'Tag',
      String skill = 'alltag',
      List<int>? days,
    }) => d.tasks.add(
      TaskItem(
        id: d.nextId('t'),
        title: title,
        icon: icon,
        time: time,
        steps: steps,
        routine: routine,
        skill: skill,
        days: days,
        showInPlan:
            routine != 'Abend' && ['tooth', 'bag', 'gift'].contains(icon),
      ),
    );
    t('Zähne putzen', 'tooth', '07:30', [
      'Hol deine Zahnbürste und etwas Zahnpasta.',
      'Putze alle Seiten deiner Zähne. Ein Erwachsener kann nachputzen.',
      'Spüle die Bürste ab und lege sie zurück.',
    ], routine: 'Morgen');
    t('Anziehen', 'shirt', '07:40', [
      'Such mit einem Erwachsenen passende Kleidung aus.',
      'Zieh zuerst ein Kleidungsstück an, dann das nächste.',
      'Wenn etwas schwierig ist, hol dir Hilfe.',
    ], routine: 'Morgen');
    t(
      'Frühstücksplatz abräumen',
      'bowl',
      '08:15',
      [
        'Bring deinen Becher und Teller an den vereinbarten Platz.',
        'Frag bei schweren oder zerbrechlichen Dingen nach Hilfe.',
        'Wische kleine Krümel gemeinsam weg.',
      ],
      routine: 'Morgen',
      skill: 'hilfe',
    );
    t(
      'Ranzen packen',
      'bag',
      '08:30',
      [
        'Schaut gemeinsam nach, was du heute brauchst.',
        'Pack dein Getränk und deine Sachen ein.',
        'Mach die Tasche zu und stell sie bereit.',
      ],
      routine: 'Morgen',
      days: [1, 2, 3, 4, 5],
    );
    t('Zimmer aufräumen', 'gift', '17:00', [
      'Such dir eine kleine Ecke aus.',
      'Leg drei Spielsachen an ihren Platz.',
      'Mach eine Pause oder räum gemeinsam weiter.',
    ], skill: 'hilfe');
    t('10 Minuten lesen', 'book', '16:30', [
      'Such dir ein Buch aus.',
      'Lies selbst oder lass dir vorlesen. Beides zählt.',
      'Sprecht über eine Stelle, die euch gefällt.',
    ], skill: 'lesen');
    t('Tisch helfen decken', 'cutlery', '18:00', [
      'Frag, welche sicheren Dinge du tragen darfst.',
      'Leg Teller oder Besteck auf den Tisch.',
      'Zählt zusammen, ob jede Person einen Platz hat.',
    ], skill: 'hilfe');
    t(
      'Spielzeug aufräumen',
      'gift',
      '18:45',
      [
        'Leg einige Spielsachen in ihre Kiste.',
        'Nimm kleine Schritte und hol dir Hilfe.',
      ],
      routine: 'Abend',
      skill: 'hilfe',
    );
    t('Zähne putzen', 'tooth', '19:00', [
      'Hol die Zahnbürste.',
      'Putzt gründlich und lasst einen Erwachsenen nachputzen.',
    ], routine: 'Abend');
    t('Schlafanzug anziehen', 'shirt', '19:10', [
      'Such deinen Schlafanzug.',
      'Zieh ihn in deinem Tempo an.',
    ], routine: 'Abend');
    t(
      'Geschichte lesen',
      'book',
      '19:20',
      ['Kuschelt euch zusammen.', 'Lies oder höre eine Geschichte.'],
      routine: 'Abend',
      skill: 'lesen',
    );
    t('Kuscheltier holen', 'teddy', '19:35', [
      'Hol dein Lieblingskuscheltier.',
      'Mach es dir gemütlich.',
    ], routine: 'Abend');
    t('Gute Nacht sagen', 'bed', '19:45', [
      'Sagt euch gemeinsam gute Nacht.',
      'Du darfst erzählen, was du noch brauchst.',
    ], routine: 'Abend');
    for (final a in [
      ['Kinobesuch', 'cinema', 30],
      ['Neues Buch', 'book', 20],
      ['Spielzeug', 'game', 25],
      ['Eis essen gehen', 'icecream', 15],
      ['Extra Vorlesezeit am Abend', 'moon', 10],
      ['Ausflug in den Zoo', 'zoo', 40],
    ]) {
      d.rewards.add(
        RewardItem(
          id: d.nextId('r'),
          title: a[0] as String,
          icon: a[1] as String,
          cost: a[2] as int,
        ),
      );
    }
    for (final a in [
      ['Aufstehen', 'bed', '07:00'],
      ['Frühstück', 'bowl', '08:00'],
      ['Mittagessen', 'cutlery', '12:30'],
      ['Hausaufgaben', 'book', '14:00'],
    ]) {
      d.plans.add(
        PlanItem(id: d.nextId('p'), title: a[0], icon: a[1], time: a[2]),
      );
    }
  }
}
