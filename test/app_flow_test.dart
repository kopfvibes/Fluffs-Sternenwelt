import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluffs_sternenwelt/main.dart';
import 'package:fluffs_sternenwelt/data/controller.dart';
import 'package:fluffs_sternenwelt/data/repository.dart';
import 'package:fluffs_sternenwelt/screens/parents_screen.dart';
import 'fixtures.dart';

Future<void> start(WidgetTester tester, AppController controller) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(FluffsApp(controller: controller));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> parents(WidgetTester tester, {String pin = '1234'}) async {
  await tap(tester, find.byKey(const ValueKey('nav-4')));
  await tester.scrollUntilVisible(
    find.text('Elternbereich'),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tap(tester, find.text('Elternbereich'));
  await tester.enterText(find.byKey(const ValueKey('parent-pin')), pin);
  await tap(tester, find.byKey(const ValueKey('unlock-parents')));
}

Future<void> save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tap(tester, find.text('Speichern'));
}

Future<void> back(WidgetTester tester) async =>
    tap(tester, find.byIcon(Icons.chevron_left_rounded).first);

void main() {
  late TestWorld world;
  late AppController c;
  setUpAll(() async {
    await initializeDateFormatting('de_DE');
    final font = FontLoader('Nunito');
    for (final weight in [400, 600, 700, 800, 900]) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    world = TestWorld();
    await world.init();
    c = world.controller;
  });
  tearDown(() => c.dispose());

  testWidgets(
    'Completing a task celebrates, opens the next task and keeps navigation real',
    (tester) async {
      await start(tester, c);
      await tap(tester, find.byKey(const ValueKey('start-tasks')));
      await tap(tester, find.text('Zähne putzen'));
      await tap(tester, find.byKey(const ValueKey('complete-task')));
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(c.balance(), 1);
      await tap(tester, find.byKey(const ValueKey('next-task')));
      expect(find.text('Anziehen'), findsWidgets);
      await tap(tester, find.text('Später weiter'));
      await tap(tester, find.byKey(const ValueKey('nav-2')));
      expect(find.text('Mein Sternenglas'), findsOneWidget);
      await tap(tester, find.text('Meine Wunschkiste'));
      expect(find.text('Kinobesuch'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('nav-3')));
      expect(find.text('Wie fühlst du dich?'), findsOneWidget);
      expect(c.balance(), 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Tapping the Fluff face in a feeling card saves that feeling without stars',
    (tester) async {
      await start(tester, c);
      await tap(tester, find.byKey(const ValueKey('nav-3')));
      await tap(tester, find.byKey(const ValueKey('feeling-traurig')));
      expect(c.currentFeeling, 'traurig');
      expect(c.balance(), 0);
      expect(find.text('traurig'), findsWidgets);
      Navigator.of(tester.element(find.byType(BottomSheet).last)).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'PIN rejects wrong entry and a newly added child is immediately selectable',
    (tester) async {
      await start(tester, c);
      await parents(tester, pin: '0000');
      expect(find.text('Die PIN stimmt nicht.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('parent-pin')), '1234');
      await tap(tester, find.byKey(const ValueKey('unlock-parents')));
      await tap(tester, find.text('Kinderprofile\nverwalten'));
      await tap(tester, find.text('Kind hinzufügen'));
      await tester.enterText(find.byKey(const ValueKey('child-name')), 'Ben');
      await tap(tester, find.byKey(const ValueKey('save-child')));
      expect(find.text('Ben'), findsOneWidget);
      await tap(tester, find.text('Ben'));
      expect(c.child.name, 'Ben');
      expect(c.data.children.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Leaving and returning to the app locks the complete parent navigation',
    (tester) async {
      await start(tester, c);
      await parents(tester);
      expect(find.byType(ParentHub), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(ParentRoot), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Parents can create tasks, rewards, plan items and change the PIN through forms',
    (tester) async {
      await start(tester, c);
      await parents(tester);
      await tap(tester, find.text('Aufgaben\nverwalten'));
      await tap(tester, find.byTooltip('Aufgabe hinzufügen'));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Pflanze gießen',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Hol mit einem Erwachsenen Wasser.',
      );
      await save(tester);
      expect(c.data.tasks.any((t) => t.title == 'Pflanze gießen'), isTrue);
      await tester.scrollUntilVisible(
        find.text('Pflanze gießen'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Pflanze gießen'), findsOneWidget);
      await back(tester);
      await tap(tester, find.text('Belohnungen'));
      await tap(tester, find.byTooltip('Belohnung hinzufügen'));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Gemeinsam malen',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '7');
      await save(tester);
      expect(
        c.data.rewards.any((r) => r.title == 'Gemeinsam malen' && r.cost == 7),
        isTrue,
      );
      await back(tester);
      await tap(tester, find.text('Tagesplan'));
      await tap(tester, find.byTooltip('Planpunkt hinzufügen'));
      await tester.enterText(find.byType(TextFormField).at(0), 'Bastelzeit');
      await tester.enterText(find.byType(TextFormField).at(1), '13:15');
      await save(tester);
      expect(c.data.plans.any((p) => p.title == 'Bastelzeit'), isTrue);
      expect(find.text('Bastelzeit'), findsOneWidget);
      await back(tester);
      await tap(tester, find.text('Einstellungen'));
      await tap(tester, find.text('Eltern-PIN ändern'));
      await tester.enterText(find.byType(TextFormField).at(0), '9876');
      await tester.enterText(find.byType(TextFormField).at(1), '9876');
      await save(tester);
      expect(c.verifyPin('1234'), isFalse);
      expect(c.verifyPin('9876'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'First launch creates the first real profile and the chosen PIN',
    (tester) async {
      final fresh = AppController(MemoryRepository(), clock: () => world.time);
      await fresh.init();
      await fresh.settings(motion: false, sound: false, haptics: false);
      await start(tester, fresh);
      await tester.enterText(find.byKey(const ValueKey('setup-name')), 'Luán');
      await tester.enterText(find.byKey(const ValueKey('setup-pin')), '9876');
      await tester.enterText(find.byType(TextFormField).last, '9876');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('finish-setup')));
      expect(fresh.data.children.single.name, 'Luán');
      expect(fresh.verifyPin('9876'), isTrue);
      expect(find.text('Hallo Luán!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fresh.dispose();
    },
  );
  testWidgets(
    'A child wish appears immediately and parent approval debits it once',
    (tester) async {
      await world.credit(10);
      await start(tester, c);
      await tap(tester, find.byKey(const ValueKey('nav-2')));
      await tap(tester, find.text('Meine Wunschkiste'));
      await tap(tester, find.text('Extra Vorlesezeit am Abend'));
      await tap(tester, find.text('Wunsch anfragen'));
      expect(c.data.requests.single.status, 'offen');
      expect(c.balance(), 10);
      expect(find.textContaining('Wartet auf'), findsWidgets);
      await parents(tester);
      await tap(tester, find.text('Belohnungen'));
      await tap(tester, find.text('Freigeben'));
      await tap(tester, find.text('Bestätigen'));
      expect(c.data.requests.single.status, 'erfüllt');
      expect(c.balance(), 0);
      expect(c.data.stars.where((e) => e.source == 'reward').length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
