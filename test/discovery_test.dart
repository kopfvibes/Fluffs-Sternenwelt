import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluffs_sternenwelt/data/controller.dart';
import 'package:fluffs_sternenwelt/data/creative.dart';
import 'package:fluffs_sternenwelt/data/discovery.dart';
import 'package:fluffs_sternenwelt/data/models.dart';
import 'package:fluffs_sternenwelt/data/repository.dart';
import 'package:fluffs_sternenwelt/screens/creative_pages.dart';
import 'package:fluffs_sternenwelt/screens/discovery_pages.dart';
import 'package:fluffs_sternenwelt/screens/parents_screen.dart';
import 'package:fluffs_sternenwelt/screens/pro_pages.dart';
import 'package:fluffs_sternenwelt/services/fluff_printing.dart';
import 'package:fluffs_sternenwelt/services/pro_license.dart';
import 'package:fluffs_sternenwelt/widgets/common.dart';

class FixedFactory extends GameFactory {
  @override
  List<int> memoryCards(int age) => [0, 1, 0, 1];

  @override
  LearningQuestion question(String game, int age) =>
    const LearningQuestion('Zähle die Sterne', '⭐ ⭐', ['2', '3', '1'], 0, 'Zwei Sterne.');
}

class LessonFactory extends FixedFactory {
  @override
  LearningQuestion question(String game, int age) => switch (game) {
    'shapes' => LearningQuestion('Welche Form ist das?', '■',
      const ['Kreis','Dreieck','Quadrat','Stern'], 2, lessonWord('shape.square.fact'),
      shape: 'square'),
    'patterns' => LearningQuestion('Was kommt als Nächstes?', '🔵 🟡 🔵 🟡 🔵 ?',
      const ['🟡','⭐','💙'], 0, lessonWord('pattern.0.1.fact'), unit: const ['🔵','🟡']),
    'feelings' => feelingQuestions.first,
    'kindness' => kindnessQuestions[3],
    _ => super.question(game,age),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController c;
  late MemoryRepository repository;
  late String code;
  late ProLicenseVerifier verifier;
  setUpAll(() async {
    await initializeDateFormatting('de_DE');
    final font = FontLoader('Nunito');
    for (final weight in [400, 600, 700, 800, 900]) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
  });
  setUp(() async {
    final algorithm = Ed25519();
    final key = await algorithm.newKeyPairFromSeed(List.generate(32, (i) => i + 1));
    final public = await key.extractPublicKey();
    verifier = ProLicenseVerifier(publicKey: base64.encode(public.bytes));
    final message = utf8.encode(jsonEncode({'v': 1, 'product': 'fluff-pro',
      'edition': 'family', 'id': '0123456789abcdef0123456789abcdef'}));
    final signature = await algorithm.sign(message, keyPair: key);
    code = 'FLUFF1.${base64Url.encode(message).replaceAll('=', '')}.'
      '${base64Url.encode(signature.bytes).replaceAll('=', '')}';
    repository = MemoryRepository();
    c = AppController(repository, licenses: verifier,
      clock: () => DateTime(2026, 10, 9, 10));
    await c.init();
    await c.setup('Mia', 5, 0, '1234');
    await c.settings(motion: false, sound: false, haptics: false);
  });
  tearDown(() => c.dispose());

  test('Pro rejects forged codes and survives a saved restart', () async {
    expect(c.proActive, isFalse);
    await expectLater(c.activatePro('FLUFF1.fake.fake'), throwsFormatException);
    expect(c.proActive, isFalse);
    await c.activatePro(code);
    expect(c.proActive, isTrue);
    expect(await verifier.verify(code.replaceFirst('FLUFF1', 'FLUFF2')), isFalse);
    final tampered = code.split('.');
    tampered[1] = base64Url.encode(utf8.encode('{"v":1,"product":"other"}'));
    expect(await verifier.verify(tampered.join('.')), isFalse);
    final restarted = AppController(repository, licenses: verifier);
    await restarted.init();
    expect(restarted.proActive, isTrue);
    restarted.dispose();
  });

  test('v4 data migrates without losing profiles or creating Pro access', () {
    final old = c.data.toJson()..remove('proLicense')..remove('gameWins')..remove('drawings');
    old['proActive'] = true;
    final migrated = AppData.fromJson(old);
    expect(migrated.children.single.name, 'Mia');
    expect(migrated.proLicense, isEmpty);
    expect(migrated.gameWins, isEmpty);
    expect(migrated.drawings, isEmpty);
  });

  test('Games require Pro and keep achievements separate for each child', () async {
    final mia = c.child.id;
    await expectLater(c.completeGame('count', childId: mia), throwsStateError);
    await c.activatePro(code);
    await c.completeGame('count', childId: mia);
    await c.completeGame('count', childId: mia);
    expect(c.gameCount('count'), 2);
    expect(c.balance(), 0);
    await c.addChild('Ben', 4, 1);
    final ben = c.data.children.last.id;
    await c.selectChild(ben);
    expect(c.gameCount('count'), 0);
    await c.completeGame('count', childId: mia);
    expect(c.gameCount('count', childId: mia), 3);
    expect(c.gameCount('count', childId: ben), 0);
  });

  test('Drawings persist through backup and belong to the original child', () async {
    await c.activatePro(code);
    final mia = c.child.id;
    final strokes = [DrawStroke(color: 0xff278df4, width: .015,
      points: const [DrawPoint(.2, .3), DrawPoint(.4, .6)])];
    await c.saveDrawing(0, strokes, childId: mia);
    final id = c.childDrawings.single.id;
    await c.saveDrawing(0, strokes, childId: mia, drawingId: id);
    expect(c.childDrawings.length, 1);
    await c.addChild('Ben', 4, 1);
    await c.selectChild(c.data.children.last.id);
    expect(c.childDrawings, isEmpty);
    await c.restoreBackup(c.exportBackup());
    await c.selectChild(mia);
    expect(c.childDrawings.single.strokes.single.points.last.y, .6);
    final root = jsonDecode(c.exportBackup());
    root['backup']['drawings'][0]['strokes'][0]['points'][0][0] = 1.5;
    await expectLater(c.restoreBackup(jsonEncode(root)), throwsFormatException);
  });

  test('All drawing templates require Pro, including a blank canvas', () async {
    final before = c.exportBackup();
    for (final template in [0, 1, 12]) {
      await expectLater(c.saveDrawing(template, [], childId: c.child.id),
        throwsStateError);
    }
    expect(c.exportBackup(), before);
    await c.activatePro(code);
    for (final template in [0, 1, 12]) {
      await c.saveDrawing(template, [], childId: c.child.id);
    }
    expect(c.childDrawings.length, 3);
  });

  test('All game variants generate valid age-appropriate questions', () {
    final factory = GameFactory(random: Random(17));
    for (final age in [3, 5, 8]) {
      final cards = factory.memoryCards(age);
      expect(cards.length, age < 5 ? 4 : age < 7 ? 6 : 8);
      for (final card in cards.toSet()) {
        expect(cards.where((x) => x == card).length, 2);
      }
      for (final game in gameIds.where((id) => id != 'memory')) {
        for (var i = 0; i < 20; i++) {
          final q = factory.question(game, age);
          expect(q.correct, inInclusiveRange(0, q.answers.length - 1));
          expect(q.answers.toSet().length, q.answers.length);
          expect(q.explanation, isNotEmpty);
        }
      }
    }
  });

  testWidgets('Basic discovery opens the parent gate rather than a game', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: Scaffold(body: DiscoveryPage(controller: c))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paare finden'));
    await tester.pumpAndSettle();
    expect(find.text('Frag deine Eltern'), findsOneWidget);
    expect(find.byType(LearningGamePage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The studio entry asks parents before exposing pictures', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: Scaffold(body: DiscoveryPage(controller: c))));
    await tester.pumpAndSettle();
    final studio = find.byKey(const ValueKey('open-studio'));
    await tester.scrollUntilVisible(studio, 160,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(studio);
    await tester.pumpAndSettle();
    expect(find.text('Frag deine Eltern'), findsOneWidget);
    expect(find.byType(CreativeStudioPage), findsNothing);
    expect(find.byType(DrawingSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The parent print tile sends Basic users to Pro activation', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: ParentRoot(controller: c)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Malbuch drucken'));
    await tester.pumpAndSettle();
    expect(find.byType(ProPage), findsOneWidget);
    expect(find.byType(PrintBookPage), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('pro-code')), 160,
      scrollable: find.descendant(of: find.byType(ProPage),
        matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pro-code')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A direct print route hides every preview until Pro is active', (tester) async {
    final basicBackup = c.exportBackup();
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: Scaffold(body: PrintBookPage(controller: c))));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Diese Seite drucken'), findsNothing);
    expect(find.text('Diese Seite als PDF speichern'), findsNothing);
    expect(find.text('Ganzes Malbuch als PDF'), findsNothing);
    await c.activatePro(code);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Diese Seite drucken'), findsOneWidget);
    await c.restoreBackup(basicBackup);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Diese Seite drucken'), findsNothing);
    expect(find.byKey(const ValueKey('open-pro-access')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Direct studio and drawing routes protect saved artwork without Pro', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: CreativeStudioPage(controller: c)));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey('free-drawing')), findsNothing);
    expect(find.text('Mein Bilderalbum'), findsNothing);
    await c.activatePro(code);
    await c.saveDrawing(1, [DrawStroke(color: 0xff278df4, width: .015,
      points: const [DrawPoint(.2, .3)])], childId: c.child.id);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('free-drawing')), findsOneWidget);
    final saved = c.childDrawings.single;
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: DrawingPage(controller: c, template: saved.template, saved: saved)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawing-canvas')), findsOneWidget);
    final backup = jsonDecode(c.exportBackup());
    backup['backup']['proLicense'] = '';
    await c.restoreBackup(jsonEncode(backup));
    await tester.pumpAndSettle();
    expect(c.childDrawings.length, 1);
    expect(find.byType(DrawingSurface), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey('save-drawing')), findsNothing);
    expect(find.byTooltip('Mit Eltern als PDF teilen'), findsNothing);
    await c.activatePro(code);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawing-canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A full quiz grants one discovery sticker and no task stars', (tester) async {
    await c.activatePro(code);
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: LearningGamePage(controller: c, game: 'count', factory: FixedFactory())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-learning')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      for (var star = 0; star < 2; star++) {
        final target = find.byKey(ValueKey('count-star-$star'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      final answer = find.widgetWithText(GlossyButton, '2');
      await tester.ensureVisible(answer);
      await tester.pumpAndSettle();
      await tester.tap(answer);
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey('next-question'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('Entdeckt!'), findsOneWidget);
    expect(c.gameCount('count'), 1);
    expect(c.balance(), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Memory permits retries and saves one sticker after every pair', (tester) async {
    await c.activatePro(code);
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(), home:
      LearningGamePage(controller: c, game: 'memory', factory: FixedFactory())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-learning')));
    await tester.pumpAndSettle();
    Future<void> card(int i) async {
      final target = find.byKey(ValueKey('memory-card-$i'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pump();
    }
    await card(0);
    await card(1);
    expect(find.textContaining('Diese Bilder sind verschieden.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(c.gameCount('memory'), 0);
    expect(find.byType(ArtIcon), findsNWidgets(2));
    final reset = find.byKey(const ValueKey('memory-reset'));
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.byType(ArtIcon), findsNothing);
    for (final i in [0, 2, 1, 3]) { await card(i); }
    await tester.pump(const Duration(seconds: 5));
    expect(c.gameCount('memory'), 0);
    final finish = find.byKey(const ValueKey('memory-finish'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(find.text('Entdeckt!'), findsOneWidget);
    expect(c.gameCount('memory'), 1);
    expect(c.balance(), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Drawing works and fits a small display with large text', (tester) async {
    await c.activatePro(code);
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.5)), child: child!),
      home: DrawingPage(controller: c, template: 0)));
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('drawing-canvas'));
    await tester.drag(canvas, const Offset(40, 30));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-drawing')));
    await tester.pumpAndSettle();
    expect(c.childDrawings.single.strokes, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  test('All twelve workbook pages are bundled and generate a printable PDF', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = await FluffPrinting.book(List.generate(12, (i) => i + 1));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(100000));
  });

  Future<void> tapLesson(WidgetTester tester, Finder target) async {
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(target, 180,
      scrollable: find.byType(Scrollable).first, maxScrolls: 50);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }
  Future<GlobalKey> openLesson(WidgetTester tester, String game,
    {double scale = 1, double width = 390}) async {
    await c.activatePro(code);
    tester.view.physicalSize = Size(width*2,1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    final preview=GlobalKey();
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale)), child: child!),
      home: RepaintBoundary(key: preview, child: LearningGamePage(key: UniqueKey(),
        controller: c, game: game, factory: LessonFactory()))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('answer-0')), findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('start-learning')));
    return preview;
  }
  Future<void> lessonPreview(WidgetTester tester, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('RENDER_PREVIEWS')) return;
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary=key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image=await boundary.toImage(pixelRatio:2);
      final data=await image.toByteData(format:ui.ImageByteFormat.png);
      final dir=Directory('previews/v5')..createSync(recursive:true);
      File('${dir.path}/Lernen-$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('Counting requires touching every star and duplicate taps do not count', (tester) async {
    final preview=await openLesson(tester,'count');
    await tapLesson(tester,find.widgetWithText(GlossyButton,'2'));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('count-star-0')));
    await tapLesson(tester,find.byKey(const ValueKey('count-star-0')));
    expect(find.text('1 von 2 Sternen angetippt'),findsOneWidget);
    await tapLesson(tester,find.widgetWithText(GlossyButton,'2'));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('count-star-1')));
    await tapLesson(tester,find.widgetWithText(GlossyButton,'3'));
    expect(find.textContaining('Vergleiche deine Zahl'),findsOneWidget);
    expect(c.gameCount('count'),0);
    await tapLesson(tester,find.widgetWithText(GlossyButton,'2'));
    expect(find.byKey(const ValueKey('next-question')),findsOneWidget);
    await lessonPreview(tester,preview,'Sterne');
    expect(tester.takeException(),isNull);
  });
  testWidgets('Shape features must be explored before naming the square', (tester) async {
    final preview=await openLesson(tester,'shapes');
    await tapLesson(tester,find.widgetWithText(GlossyButton,'Quadrat'));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    for (var i=0;i<4;i++) {
      await tapLesson(tester,find.byKey(ValueKey('shape-point-$i')));
    }
    await tapLesson(tester,find.widgetWithText(GlossyButton,'Dreieck'));
    expect(find.textContaining('vier Seiten sind gleich lang'),findsOneWidget);
    await tapLesson(tester,find.widgetWithText(GlossyButton,'Quadrat'));
    expect(find.byKey(const ValueKey('next-question')),findsOneWidget);
    await lessonPreview(tester,preview,'Formen');
    expect(tester.takeException(),isNull);
  });
  testWidgets('Pattern inspection rejects jumping ahead and help models the unit', (tester) async {
    final preview=await openLesson(tester,'patterns');
    await tapLesson(tester,find.byKey(const ValueKey('pattern-item-1')));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('lesson-help')));
    await tapLesson(tester,find.byKey(const ValueKey('explore-next')));
    await tapLesson(tester,find.byKey(const ValueKey('explore-next')));
    final answer=find.ancestor(of:find.text('gelber Kreis'),matching:find.byType(GlossyPanel));
    await tapLesson(tester,answer);
    expect(find.byKey(const ValueKey('next-question')),findsOneWidget);
    expect(c.gameCount('patterns'),0);
    await lessonPreview(tester,preview,'Muster');
    expect(tester.takeException(),isNull);
  });
  testWidgets('Memory help shows a pair but never finds it on the child behalf', (tester) async {
    final preview=await openLesson(tester,'memory');
    await tapLesson(tester,find.byKey(const ValueKey('lesson-help')));
    expect(find.byType(ArtIcon),findsNWidgets(2));
    expect(c.gameCount('memory'),0);
    await tester.pump(const Duration(seconds:20));
    expect(find.byType(ArtIcon),findsNWidgets(2));
    await lessonPreview(tester,preview,'Memory-Hilfe');
    await tapLesson(tester,find.byKey(const ValueKey('memory-reset')));
    expect(find.byType(ArtIcon),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('memory-card-0')));
    await tapLesson(tester,find.byKey(const ValueKey('memory-card-2')));
    expect(find.text('1 von 2 Paaren gefunden'),findsOneWidget);
    expect(c.gameCount('memory'),0);
    expect(tester.takeException(),isNull);
  });
  testWidgets('An unexpected personal feeling is valid and guided breathing needs six steps', (tester) async {
    final before=c.data.feelings.length;
    final preview=await openLesson(tester,'feelings');
    await tapLesson(tester,find.widgetWithText(GlossyButton,'Glücklich'));
    expect(find.textContaining('Glücklich. Du darfst deine Freude zeigen.'),findsOneWidget);
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('support-breathe')));
    for (var i=0;i<5;i++) {
      await tapLesson(tester,find.byKey(const ValueKey('breathe-step')));
      expect(find.byKey(const ValueKey('next-question')),findsNothing);
    }
    await tapLesson(tester,find.byKey(const ValueKey('breathe-step')));
    expect(find.byKey(const ValueKey('next-question')),findsOneWidget);
    expect(c.data.feelings.length,before);
    expect(c.gameCount('feelings'),0);
    await lessonPreview(tester,preview,'Gefuehle-Atmen');
    expect(tester.takeException(),isNull);
  });
  testWidgets('Uncertainty and help seeking practice are valid without a microphone', (tester) async {
    await openLesson(tester,'feelings');
    await tapLesson(tester,find.widgetWithText(GlossyButton,'Weiß ich noch nicht'));
    await tapLesson(tester,find.byKey(const ValueKey('support-talk')));
    expect(find.byKey(const ValueKey('support-done')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('talk-sentence-2')));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('support-done')));
    expect(find.byKey(const ValueKey('next-question')),findsOneWidget);
    await tapLesson(tester,find.byKey(const ValueKey('support-pause')));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tester.pump(const Duration(seconds:20));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('support-done')));
    expect(find.byKey(const ValueKey('next-question')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('Kindness requires a phrase and a safe follow up response before advancing', (tester) async {
    final preview=await openLesson(tester,'kindness');
    await tapLesson(tester,find.widgetWithText(GlossyButton,'Nein sagen. Mein Körper gehört mir.'));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('try-phrase')));
    await tapLesson(tester,find.byKey(const ValueKey('practice-answer-1')));
    expect(find.byKey(const ValueKey('next-question')),findsNothing);
    await tapLesson(tester,find.byKey(const ValueKey('practice-answer-0')));
    expect(find.byKey(const ValueKey('next-question')),findsOneWidget);
    expect(c.gameCount('kindness'),0);
    await lessonPreview(tester,preview,'Alltag');
    expect(tester.takeException(),isNull);
  });
  testWidgets('Learning route hides its activities when Pro or child identity changes', (tester) async {
    await openLesson(tester,'count');
    final data=jsonDecode(c.exportBackup());
    data['backup']['proLicense']='';
    await c.restoreBackup(jsonEncode(data));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('count-star-0')),findsNothing);
    await c.activatePro(code);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('count-star-0')),findsOneWidget);
    await c.addChild('Ben',4,1);
    await c.selectChild(c.data.children.last.id);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('count-star-0')),findsNothing);
    expect(c.gameCount('count'),0);
    expect(tester.takeException(),isNull);
  });
  testWidgets('All six guided lessons fit small screens with large text', (tester) async {
    for (final game in gameIds) {
      await openLesson(tester,game,scale:1.5,width:320);
      await tapLesson(tester,find.byKey(const ValueKey('lesson-help')));
      expect(tester.takeException(),isNull,reason:game);
    }
  });

  testWidgets('Render real v5 discovery and drawing previews', (tester) async {
    if (!const bool.fromEnvironment('RENDER_PREVIEWS')) return;
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    final dir = Directory('previews/v5')..createSync(recursive: true);
    for (final item in <(String, Widget)>[
      ('Malatelier-ohne-Pro', CreativeStudioPage(controller: c)),
      ('Malbuch-ohne-Pro', Scaffold(body: PrintBookPage(controller: c))),
      ('Elternbereich-ohne-Pro', ParentRoot(controller: c)),
      ('Entdeckerwelt', Scaffold(body: DiscoveryPage(controller: c))),
      ('Malatelier', CreativeStudioPage(controller: c)),
      ('Paare-finden', LearningGamePage(controller: c, game: 'memory')),
      ('Sterne-zaehlen', LearningGamePage(controller: c, game: 'count')),
      ('Formen-entdecken', LearningGamePage(controller: c, game: 'shapes')),
      ('Muster-weiterdenken', LearningGamePage(controller: c, game: 'patterns')),
      ('Gefuehle-verstehen', LearningGamePage(controller: c, game: 'feelings')),
      ('Gemeinsam-handeln', LearningGamePage(controller: c, game: 'kindness')),
      ('Ausmalen', DrawingPage(controller: c, template: 1)),
    ]) {
      if (item.$1 == 'Entdeckerwelt') await c.activatePro(code);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(theme: fluffTheme(), home:
        RepaintBoundary(key: key, child: item.$2)));
      await tester.pumpAndSettle();
      if (item.$2 is LearningGamePage) {
        await tester.tap(find.byKey(const ValueKey('start-learning')));
        await tester.pumpAndSettle();
      }
      final context = tester.element(find.byType(RepaintBoundary).first);
      await tester.runAsync(() async {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        for (final asset in manifest.listAssets().where((name) =>
            name.startsWith('assets/art/') || name.startsWith('assets/coloring/'))) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/${item.$1}.png').writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
