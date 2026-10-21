import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffs_sternenwelt/data/controller.dart';
import 'package:fluffs_sternenwelt/data/enchanted_stories.dart';
import 'package:fluffs_sternenwelt/screens/enchanted_story_pages.dart';
import 'package:fluffs_sternenwelt/widgets/common.dart';
import 'fixtures.dart';

Future<void> storyTap(WidgetTester tester, String key) async {
  final button = find.byKey(ValueKey(key));
  await tester.pumpAndSettle();
  if (button.evaluate().isEmpty) {
    await tester.scrollUntilVisible(button, 130,
      scrollable: find.byType(Scrollable).last);
  }
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sixty unique three-scene child stories with safe interactive choices', () {
    expect(enchantedStories.length, 60);
    expect(enchantedStories.map((x) => x.title).toSet().length, 60);
    for (final s in enchantedStories) {
      expect(s.opening.length, greaterThan(28), reason: s.title);
      expect(s.challenge.length, greaterThan(28), reason: s.title);
      expect(s.ending.length, greaterThan(28), reason: s.title);
      expect(s.optionA, isNot(s.optionB), reason: s.title);
      expect(s.answerA, isNot(s.answerB), reason: s.title);
      expect(s.heart.length, greaterThan(12), reason: s.title);
      expect(s.question, contains('?'), reason: s.title);
    }
  });

  test('Daily story changes by calendar date without DST or midnight drift', () {
    expect(dailyEnchantedStory(DateTime(2026, 10, 21, 23, 59)), 0);
    expect(dailyEnchantedStory(DateTime(2026, 10, 22, 0, 1)), 1);
    expect(dailyEnchantedStory(DateTime(2026, 12, 19)), 59);
    expect(dailyEnchantedStory(DateTime(2026, 12, 20)), 0);
    expect(dailyEnchantedStory(DateTime(2026, 10, 20)), 0);
    expect(dailyEnchantedStory(DateTime(2027, 3, 28, 23, 59)),
      dailyEnchantedStory(DateTime(2027, 3, 28, 0, 0)));
  });

  test('Completion survives local save/restart and is separate per child', () async {
    final world = TestWorld();
    world.time = DateTime(2026, 10, 21, 10);
    await world.init();
    final c = world.controller;
    final first = c.child.id;
    final beforeBalance = c.balance();
    final beforeEntries = c.data.stars.length;
    await c.completeStory(0, childId: first);
    await c.completeStory(0, childId: first);
    expect(c.storyDone(0), isTrue);
    expect(c.data.storyCompleted.length, 1);
    expect(c.balance(), beforeBalance);
    expect(c.data.stars.length, beforeEntries);
    await expectLater(c.completeStory(1, childId: first), throwsStateError);
    await c.addChild('Ben', 3, 1);
    await c.selectChild(c.data.children.last.id);
    expect(c.storyDone(0), isFalse);
    final reloaded = AppController(world.repository, clock: () => world.time);
    await reloaded.init();
    expect(reloaded.storyDone(0), isFalse);
    await reloaded.selectChild(first);
    expect(reloaded.storyDone(0), isTrue);
    expect(reloaded.balance(), beforeBalance);
    reloaded.dispose();
    c.dispose();
  });

  testWidgets('Child interacts in three scenes and receives a saved book memory',
      (tester) async {
    final world = TestWorld();
    world.time = DateTime(2026, 10, 21, 10);
    await world.init();
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: EnchantedStoryLibrary(controller: world.controller)));
    expect(find.text('Der verirrte Stern'), findsOneWidget);
    await storyTap(tester, 'open-daily-story');
    expect(find.text('Szene 1 von 3'), findsOneWidget);
    await storyTap(tester, 'story-next');
    expect(find.text('Szene 2 von 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('story-choice-feedback')), findsNothing);
    await storyTap(tester, 'story-choice-b');
    expect(find.byKey(const ValueKey('story-choice-feedback')), findsOneWidget);
    await storyTap(tester, 'story-resolve');
    expect(find.text('Szene 3 von 3'), findsOneWidget);
    final before = world.controller.balance();
    await storyTap(tester, 'story-complete');
    expect(world.controller.storyDone(0), isTrue);
    expect(world.controller.balance(), before);
    await tester.pumpWidget(const SizedBox.shrink());
    world.controller.dispose();
  });
}
