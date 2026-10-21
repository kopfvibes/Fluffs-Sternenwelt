import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluffs_sternenwelt/data/companion.dart';
import 'package:fluffs_sternenwelt/data/discovery.dart';
import 'package:fluffs_sternenwelt/screens/extra_pages.dart';
import 'package:fluffs_sternenwelt/screens/fluff_day.dart';
import 'package:fluffs_sternenwelt/screens/reward_explanation.dart';
import 'package:fluffs_sternenwelt/screens/task_flow.dart';
import 'package:fluffs_sternenwelt/widgets/common.dart';
import 'fixtures.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // Dialog buttons and lower wish cards can be lazily built off screen.
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty && find.byType(Scrollable).evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      finder, 160,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 40,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}
Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('RENDER_PREVIEWS')) return;
  await tester.pump(const Duration(milliseconds: 100));
  final image = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
    .toImage(pixelRatio: 2);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('previews/v5.2/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
  image.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('de_DE');
    final font = FontLoader('Nunito');
    for (final weight in [400, 600, 700, 800, 900]) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late TestWorld world;
  setUp(() async { world = TestWorld(); await world.init(); });
  tearDown(() => world.controller.dispose());

  test('The example is 30 minus 5 equals 25, without spending during explanation', () async {
    final c = world.controller;
    await world.credit(30);
    final reward = c.data.rewards.firstWhere((r) => r.title == 'Kinobesuch');
    reward.cost = 5;
    await c.saveReward(reward);
    final math = RewardExplanation(balance: c.balance(), cost: reward.cost, title: reward.title);
    expect(math.remaining, 25);
    expect(math.summary, contains('25 Sterne'));
    expect(math.narration, containsAllInOrder(['30', 'Kinobesuch', '5', '25']));
    expect(c.balance(), 30);
    await c.requestReward(reward);
    expect(c.balance(), 30);
    await c.decideRequest(c.data.requests.single.id, 'erfüllt');
    expect(c.balance(), 25);
    final story = lastRewardNarration(c);
    expect(story, containsAllInOrder(['30', '5', '25']));
    await c.decideRequest(c.data.requests.single.id, 'erfüllt');
    expect(c.balance(), 25);
  });

  test('An unaffordable wish explains missing stars and never offers a negative jar', () {
    const math = RewardExplanation(balance: 3, cost: 5, title: 'Kinobesuch');
    expect(math.affordable, isFalse);
    expect(math.missing, 2);
    expect(math.summary, contains('fehlen noch 2 Sterne'));
    expect(math.narration, isNot(contains('-2')));
  });

  test('Every jar bundle adds up exactly, including totals larger than 34', () {
    for (final count in [0, 1, 25, 30, 31, 34, 35, 99, 999, 9999, 999999999]) {
      expect(jarTokens(count).fold(0, (n, token) => n + token), count);
      expect(jarTokens(count).length, lessThanOrEqualTo(40));
    }
  });

  test('German number phrases preserve digits and use correct order', () {
    expect(spokenNumber(30), ['30']);
    expect(spokenNumber(125), ['einhundert', '25']);
    expect(spokenNumber(2030), ['2', 'tausend', '30']);
    expect(spokenNumber(0), ['0']);
    expect(spokenNumber(-5), ['minus', '5']);
  });

  test('The daily companion reports actual completed tasks and the correct next task', () async {
    final c = world.controller;
    final first = c.dayTasks.first;
    await c.completeTask(first);
    final lines = dayNarration(c);
    expect(lines, isNot(contains(first.title)));
    expect(lines, contains(c.dayTasks[1].title));
    expect(lines, contains('Du hast einen Stern in deinem Glas.'));
    await c.addChild('Ben', 3, 1);
    await c.selectChild(c.data.children.last.id);
    expect(dayNarration(c), contains('0'));
    expect(nextDayTasks(c).first.id, first.id);
  });

  test('Three-year-olds start with round shapes and triangles', () {
    final factory = GameFactory();
    for (var i = 0; i < 100; i++) {
      expect(factory.question('shapes', 3).shape, anyOf('circle', 'triangle'));
    }
  });

  testWidgets('Young children explore a wish in three steps before sending it', (tester) async {
    final c = world.controller;
    await c.editChild(c.child.id, c.child.name, 3, c.child.avatar);
    await world.credit(30);
    final reward = c.data.rewards.firstWhere((r) => r.title == 'Kinobesuch');
    reward.cost = 5; await c.saveReward(reward);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(
      theme: fluffTheme(), home: Scaffold(body: WishlistPage(controller: c)))));
    await tapVisible(tester, find.text('Kinobesuch'));
    expect(find.byKey(const ValueKey('request-reward')), findsNothing);
    expect(find.text('Du hast 30 Sterne.'), findsOneWidget);
    await shot(tester, boundary, '01-wunsch-vorher');
    await tapVisible(tester, find.byKey(const ValueKey('reward-explain-next')));
    expect(find.text('Dein Wunsch kostet 5 Sterne.'), findsOneWidget);
    await shot(tester, boundary, '02-wunsch-kosten');
    await tapVisible(tester, find.byKey(const ValueKey('reward-explain-next')));
    expect(find.textContaining('25 Sterne in deinem Glas.'), findsOneWidget);
    final jar = tester.widget<StarJar>(find.byType(StarJar));
    expect(jar.count, 25);
    expect(c.balance(), 30);
    await shot(tester, boundary, '03-wunsch-danach');
    await tapVisible(tester, find.byKey(const ValueKey('request-reward')));
    expect(c.data.requests.single.cost, 5);
    expect(c.balance(), 30);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A three-year-old gets one task step at a time and help still counts', (tester) async {
    final c = world.controller;
    await c.editChild(c.child.id, c.child.name, 3, c.child.avatar);
    final task = c.dayTasks.first;
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(), home: Builder(builder: (context) =>
      Scaffold(body: TextButton(onPressed: () => openTask(context, c, task),
        child: const Text('Aufgabe öffnen'))))));
    await tapVisible(tester, find.text('Aufgabe öffnen'));
    expect(find.text(task.steps[0]), findsOneWidget);
    expect(find.text(task.steps[1]), findsNothing);
    expect(find.byKey(const ValueKey('complete-task')), findsNothing);
    for (var step = 1; step < task.steps.length; step++) {
      await tapVisible(tester, find.byKey(const ValueKey('next-task-step')));
      expect(find.text(task.steps[step]), findsOneWidget);
    }
    await tapVisible(tester, find.text('Ich habe Hilfe bekommen'));
    await tapVisible(tester, find.byKey(const ValueKey('complete-task')));
    expect(c.balance(), task.stars);
    expect(c.data.stars.single.assisted, isTrue);
    await tapVisible(tester, find.byKey(const ValueKey('close-celebration')));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Fluff tells a story one step at a time without altering child records', (tester) async {
    final c = world.controller;
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(
      theme: fluffTheme(), home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showFluffDay(context, c), child: const Text('Fluff öffnen')))))));
    await tapVisible(tester, find.text('Fluff öffnen'));
    await tapVisible(tester, find.byKey(const ValueKey('fluff-story')));
    await shot(tester, boundary, '04-fluffs-geschichte');
    await tapVisible(tester, find.byKey(const ValueKey('fluff-story-next')));
    expect(c.data.feelings, isEmpty);
    expect(c.balance(), 0);
    expect(c.data.requests, isEmpty);
    await tapVisible(tester, find.byTooltip('Schließen'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A child change closes an open wish before it can spend another child’s stars', (tester) async {
    final c = world.controller;
    await world.credit(30);
    final reward = c.data.rewards.first;
    await c.addChild('Ben', 3, 1);
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(), home: Scaffold(body: Builder(
      builder: (context) => TextButton(onPressed: () => explainReward(context, c, reward),
        child: const Text('Wunsch öffnen'))))));
    await tapVisible(tester, find.text('Wunsch öffnen'));
    await c.selectChild(c.data.children.last.id);
    await tester.pumpAndSettle();
    expect(find.byType(RewardExplanationDialog), findsNothing);
    expect(c.data.requests, isEmpty);
    expect(c.balance(), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Breathing waits for a child instead of enforcing a countdown', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: Scaffold(body: BreathingPage(controller: world.controller))));
    await tapVisible(tester, find.byKey(const ValueKey('breath-next')));
    expect(find.text('Rieche an einer Blume. Atme sanft ein.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 45));
    expect(find.text('Rieche an einer Blume. Atme sanft ein.'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tapVisible(tester, find.byKey(const ValueKey('breath-next')));
    }
    expect(find.text('Gut gemacht. Zeit für eine Pause.'), findsOneWidget);
    expect(world.controller.balance(), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

}
