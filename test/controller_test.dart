import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffs_sternenwelt/data/controller.dart';
import 'package:fluffs_sternenwelt/data/models.dart';
import 'package:fluffs_sternenwelt/data/repository.dart';
import 'fixtures.dart';

void main() {
  late TestWorld world;
  late AppController c;
  setUp(() async {
    world = TestWorld();
    await world.init();
    c = world.controller;
  });
  tearDown(() => c.dispose());

  test(
    'First setup stores private PIN and exactly the reference templates',
    () {
      expect(c.data.children.single.name, 'Mia');
      expect(c.dayTasks.length, 7);
      expect(c.eveningTasks.length, 6);
      expect(c.data.rewards.length, 6);
      expect(c.data.plans.length, 4);
      expect(c.dayTasks.where((t) => t.showInPlan).length, 3);
      expect(c.balance(), 0);
      expect(c.verifyPin('1234'), isTrue);
      expect(c.verifyPin('0000'), isFalse);
      expect(c.data.pinHash.length, 64);
      expect(c.data.salt.length, 48);
    },
  );
  test(
    'Task counts once per child and calendar date, also after restart',
    () async {
      final task = world.task('tooth');
      expect(await c.completeTask(task), isTrue);
      expect(await c.completeTask(task), isFalse);
      final restarted = AppController(
        world.repository,
        clock: () => world.time,
      );
      await restarted.init();
      expect(restarted.balance(), 1);
      expect(await restarted.completeTask(task), isFalse);
      world.time = addDays(world.time, 1);
      expect(await restarted.completeTask(task), isTrue);
      expect(restarted.balance(), 2);
      restarted.dispose();
    },
  );
  test(
    'Changing children isolates task progress, feelings and balances',
    () async {
      await c.completeTask(world.task('tooth'));
      await c.setFeeling('traurig');
      final mia = c.child.id;
      await c.addChild('Ben', 5, 1);
      await c.selectChild(c.data.children.last.id);
      expect(c.balance(), 0);
      expect(c.currentFeeling, isNull);
      expect(c.completed, 0);
      await c.completeTask(world.task('tooth'));
      await c.setFeeling('stolz');
      await c.selectChild(mia);
      expect(c.balance(), 1);
      expect(c.currentFeeling, 'traurig');
    },
  );
  test(
    'Assignments, inactive tasks and weekdays actually restrict awards',
    () async {
      await c.addChild('Ben', 5, 1);
      final task = TaskItem.fromJson(world.task('tooth').toJson())
        ..children = [c.data.children.last.id];
      await c.saveTask(task);
      expect(c.dayTasks.any((t) => t.id == task.id), isFalse);
      await expectLater(c.completeTask(task), throwsStateError);
      world.time = DateTime(2025, 10, 11);
      expect(c.dayTasks.any((t) => t.icon == 'bag'), isFalse);
    },
  );
  test('Changing today feeling replaces it and never awards stars', () async {
    await c.setFeeling('glücklich');
    await c.setFeeling('wütend');
    expect(c.data.feelings.length, 1);
    expect(c.currentFeeling, 'wütend');
    expect(c.balance(), 0);
    await expectLater(c.setFeeling('falsch'), throwsFormatException);
  });
  test(
    'Helper bonus can be claimed once and is invalidated by its undone step',
    () async {
      for (final t in c.dayTasks.where((t) => t.skill == 'hilfe').toList()) {
        await c.completeTask(t);
      }
      await c.claimMission('helper');
      await c.claimMission('helper');
      expect(c.balance(), 6);
      await c.undoTask(world.task('gift'));
      expect(c.balance(), 2);
      expect(c.missionClaimed('helper'), isFalse);
    },
  );
  test(
    'Reading counts distinct dates, resets weekly and preserves earned past bonus',
    () async {
      for (var i = 0; i < 3; i++) {
        await c.completeTask(world.task('book'));
        await c.completeTask(world.task('book', evening: true));
        if (i < 2) world.time = addDays(world.time, 1);
      }
      expect(c.missionProgress('reading'), 3);
      await c.claimMission('reading');
      expect(c.balance(), 11);
      world.time = DateTime(2025, 10, 13);
      expect(c.missionProgress('reading'), 0);
      expect(c.missionClaimed('reading'), isFalse);
      expect(c.balance(), 11);
    },
  );
  test(
    'Assisted tasks keep their original skill even after editing templates',
    () async {
      final task = world.task('bowl');
      await c.completeTask(task, assisted: true);
      expect(c.missionProgress('helper'), 1);
      expect(c.missionProgress('courage'), 1);
      final changed = TaskItem.fromJson(task.toJson())..skill = 'lesen';
      await c.saveTask(changed);
      expect(c.missionProgress('helper'), 1);
      expect(c.missionProgress('reading'), 0);
      await c.claimMission('courage');
      expect(c.balance(), 3);
    },
  );
  test(
    'Undoing another task preserves independent valid mission bonuses',
    () async {
      await c.completeTask(world.task('bowl'), assisted: true);
      await c.claimMission('courage');
      await c.completeTask(world.task('tooth'));
      await c.undoTask(world.task('tooth'));
      expect(c.balance(), 3);
      expect(c.missionClaimed('courage'), isTrue);
    },
  );
  test('Wishes debit only on parent approval and cannot debit twice', () async {
    await world.credit(10);
    final wish = c.data.rewards.firstWhere((r) => r.cost == 10);
    await c.requestReward(wish);
    await c.requestReward(wish);
    expect(c.data.requests.length, 1);
    expect(c.balance(), 10);
    final id = c.data.requests.single.id;
    await c.decideRequest(id, 'erfüllt');
    await c.decideRequest(id, 'erfüllt');
    expect(c.balance(), 0);
    await expectLater(c.undoTask(world.task('tooth')), throwsStateError);
    expect(c.balance(), 0);
  });
  test(
    'Insufficient funds, declined wishes and cancellations do not lose stars',
    () async {
      final wish = c.data.rewards.firstWhere((r) => r.cost == 10);
      await expectLater(c.requestReward(wish), throwsStateError);
      expect(c.data.requests, isEmpty);
      await world.credit(10);
      await c.requestReward(wish);
      await c.decideRequest(c.data.requests.single.id, 'abgelehnt');
      expect(c.balance(), 10);
      await c.requestReward(wish);
      await c.decideRequest(c.data.requests.last.id, 'zurückgezogen');
      expect(c.balance(), 10);
    },
  );
  test(
    'Failed writes leave both visible state and persisted state unchanged',
    () async {
      final before = c.exportBackup();
      world.repository.fail = true;
      await expectLater(c.completeTask(world.task('tooth')), throwsStateError);
      expect(c.exportBackup(), before);
      expect(c.busy, isFalse);
      expect(c.balance(), 0);
    },
  );
  test('Simultaneous writes are guarded instead of losing an award', () async {
    final first = c.completeTask(world.task('tooth'));
    await expectLater(c.completeTask(world.task('shirt')), throwsStateError);
    expect(await first, isTrue);
    expect(c.balance(), 1);
  });
  test(
    'Removing one child retains other children and disables personal-only tasks',
    () async {
      await c.addChild('Ben', 5, 1);
      final ben = c.data.children.last.id;
      final task = TaskItem.fromJson(world.task('tooth').toJson())
        ..children = [ben];
      await c.saveTask(task);
      await c.removeChild(ben);
      expect(c.data.children.length, 1);
      expect(c.data.tasks.firstWhere((t) => t.id == task.id).active, isFalse);
      await expectLater(c.removeChild(c.child.id), throwsStateError);
    },
  );
  test('Five failed PIN attempts cause a real 30-second cooldown', () async {
    for (var i = 0; i < 5; i++) {
      expect(c.verifyPin('0000'), isFalse);
    }
    expect(c.pinWait, 30);
    expect(c.verifyPin('1234'), isFalse);
    world.time = world.time.add(const Duration(seconds: 30));
    expect(c.pinWait, 0);
    expect(c.verifyPin('1234'), isTrue);
    final oldSalt = c.data.salt;
    await c.changePin('9876');
    expect(c.data.salt, isNot(oldSalt));
    expect(c.verifyPin('1234'), isFalse);
    expect(c.verifyPin('9876'), isTrue);
  });
  test(
    'Backup round trip retains profiles, wishes, feelings and settings',
    () async {
      await world.credit(10);
      await c.setFeeling('müde');
      await c.addChild('Ben', 5, 1);
      await c.requestReward(c.data.rewards.firstWhere((r) => r.cost == 10));
      await c.decideRequest(c.data.requests.single.id, 'erfüllt');
      final original = c.exportBackup();
      final other = AppController(MemoryRepository(), clock: () => world.time);
      await other.init();
      await other.restoreBackup(original);
      expect(other.exportBackup(), original);
      expect(other.verifyPin('1234'), isTrue);
      other.dispose();
    },
  );
  test('Invalid or failed restore never replaces existing data', () async {
    await c.completeTask(world.task('tooth'));
    final original = c.exportBackup();
    await expectLater(c.restoreBackup('{bad'), throwsFormatException);
    final altered = jsonDecode(original) as Map<String, dynamic>;
    altered['backup']['stars'][0]['amount'] = -2;
    await expectLater(
      c.restoreBackup(jsonEncode(altered)),
      throwsFormatException,
    );
    expect(c.exportBackup(), original);
    world.repository.fail = true;
    await expectLater(c.restoreBackup(original), throwsStateError);
    expect(c.exportBackup(), original);
  });
  test(
    'Past plans stay intact when templates change on a later date',
    () async {
      await c.completeTask(world.task('tooth'));
      final oldKey = '${c.child.id}|${c.today}';
      final oldPlan = List<String>.from(c.data.dailyPlans[oldKey]!);
      world.time = addDays(world.time, 1);
      await c.refresh();
      final changed = TaskItem.fromJson(world.task('shirt').toJson())
        ..active = false;
      await c.saveTask(changed);
      expect(c.data.dailyPlans[oldKey], oldPlan);
      expect(
        c.data.dailyPlans['${c.child.id}|${c.today}'],
        isNot(contains(changed.id)),
      );
    },
  );
  test('Schedule checks are separate from awarded tasks', () async {
    final plan = c.data.plans.first;
    await c.togglePlan(plan);
    expect(c.planDone(plan, c.now), isTrue);
    expect(c.balance(), 0);
    await c.togglePlan(plan);
    expect(c.planDone(plan, c.now), isFalse);
  });
  test(
    'Invalid edited profiles, tasks, rewards and schedule times are rejected',
    () async {
      await expectLater(c.addChild('', 5, 1), throwsFormatException);
      await expectLater(c.addChild('Ben', 1, 1), throwsFormatException);
      final task = TaskItem.fromJson(world.task('tooth').toJson())
        ..time = '25:00';
      await expectLater(c.saveTask(task), throwsFormatException);
      await expectLater(
        c.saveReward(RewardItem(id: '', title: 'Buch', icon: 'book', cost: 0)),
        throwsFormatException,
      );
      await expectLater(
        c.savePlan(PlanItem(id: '', title: 'Malen', icon: 'book', time: '9')),
        throwsFormatException,
      );
    },
  );
  test(
    'Malformed backup types and unknown moods are rejected safely',
    () async {
      for (final mutation in [
        (Map<String, dynamic> b) => b['children'] = 'wrong',
        (Map<String, dynamic> b) => b['feelings'] = [
          {'childId': c.child.id, 'date': c.today, 'value': 'unknown'},
        ],
        (Map<String, dynamic> b) =>
            b['dailyPlans'] = {'missing|${c.today}': []},
        (Map<String, dynamic> b) => b['tasks'][0]['icon'] = 'missing',
      ]) {
        final root = jsonDecode(c.exportBackup()) as Map<String, dynamic>;
        mutation(root['backup']);
        await expectLater(
          c.restoreBackup(jsonEncode(root)),
          throwsFormatException,
        );
      }
      expect(c.data.children.single.name, 'Mia');
    },
  );
  test('Restoring an old sequence prevents new ID collisions', () async {
    final root = jsonDecode(c.exportBackup()) as Map<String, dynamic>;
    root['backup']['sequence'] = 0;
    await c.restoreBackup(jsonEncode(root));
    await c.addChild('Ben', 5, 1);
    final all = [
      ...c.data.children.map((x) => x.id),
      ...c.data.tasks.map((x) => x.id),
      ...c.data.rewards.map((x) => x.id),
      ...c.data.plans.map((x) => x.id),
    ];
    expect(all.toSet().length, all.length);
  });
  test('Requests use the current stored price and availability', () async {
    await world.credit(10);
    final stale = c.data.rewards.firstWhere((r) => r.cost == 10);
    final edited = RewardItem.fromJson(stale.toJson())..cost = 15;
    await c.saveReward(edited);
    await expectLater(c.requestReward(stale), throwsStateError);
    expect(c.data.requests, isEmpty);
    edited.cost = 10;
    edited.active = false;
    await c.saveReward(edited);
    await expectLater(c.requestReward(stale), throwsStateError);
  });
  test('Unknown missions never grant free bonuses', () async {
    await c.completeTask(world.task('tooth'), assisted: true);
    await expectLater(c.claimMission('made-up'), throwsFormatException);
    expect(c.balance(), 1);
  });
  test(
    'Calendar arithmetic crosses DST, month and year boundaries by date',
    () {
      expect(dateKey(addDays(DateTime(2026, 10, 25), 1)), '2026-10-26');
      expect(dateKey(monday(DateTime(2026, 10, 25, 23))), '2026-10-19');
      expect(dateKey(addDays(DateTime(2025, 12, 31), 1)), '2026-01-01');
      expect(dateKey(addDays(DateTime(2024, 2, 28), 1)), '2024-02-29');
    },
  );
}
