import 'package:fluffs_sternenwelt/data/controller.dart';
import 'package:fluffs_sternenwelt/data/models.dart';
import 'package:fluffs_sternenwelt/data/repository.dart';

class TestWorld {
  DateTime time = DateTime(2025, 10, 7, 9, 41);
  final repository = MemoryRepository();
  late final AppController controller;
  Future<void> init() async {
    controller = AppController(repository, clock: () => time);
    await controller.init();
    await controller.setup('Mia', 7, 0, '1234');
    await controller.settings(motion: false, sound: false, haptics: false);
  }

  TaskItem task(String icon, {bool evening = false}) => controller.data.tasks
      .firstWhere((t) => t.icon == icon && (t.routine == 'Abend') == evening);
  Future<void> credit(int count) async {
    var remaining = count;
    while (remaining > 0) {
      for (final task in [...controller.dayTasks, ...controller.eveningTasks]) {
        if (remaining == 0) break;
        if (await controller.completeTask(task)) remaining -= task.stars;
      }
      if (remaining > 0) time = addDays(time, 1);
    }
  }
}

Future<AppController> previewController({bool motion = false}) async {
  final world = TestWorld();
  await world.init();
  final c = world.controller;
  await c.addChild('Ben', 5, 1);
  await c.addChild('Leni', 9, 2);
  final day = c.now;
  final children = c.data.children;
  for (final profile in children) {
    final amount = profile == children.first
        ? 29
        : profile == children[1]
        ? 28
        : 34;
    for (var i = 0; i < amount; i++) {
      final date = addDays(day, -1 - (i ~/ 6));
      final task = c.data.tasks[i % 6];
      final key = dateKey(date);
      c.data.stars.add(
        StarEntry(
          id: c.taskKey(profile.id, task.id, key),
          childId: profile.id,
          source: 'task',
          sourceId: task.id,
          date: key,
          label: task.title,
          amount: 1,
          skill: task.skill,
          type: profile == children.first && i < 3 ? 'mut' : task.skill,
          assisted: profile == children.first && i < 3,
        ),
      );
      c.data.dailyPlans['${profile.id}|$key'] = c.data.tasks
          .map((t) => t.id)
          .toList();
    }
  }
  for (final t in c.dayTasks.take(3).toList()) {
    await c.completeTask(t);
  }
  final book = c.data.rewards.firstWhere((r) => r.title == 'Neues Buch');
  await c.requestReward(book);
  await c.decideRequest(c.data.requests.single.id, 'erfüllt');
  await c.setFeeling('glücklich');
  await c.togglePlan(c.data.plans[0]);
  await c.togglePlan(c.data.plans[1]);
  await c.settings(motion: motion);
  return c;
}
