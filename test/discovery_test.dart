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
import 'package:fluffs_sternenwelt/services/fluff_printing.dart';
import 'package:fluffs_sternenwelt/services/pro_license.dart';
import 'package:fluffs_sternenwelt/widgets/common.dart';

class FixedFactory extends GameFactory {
  @override
  LearningQuestion question(String game, int age) =>
    const LearningQuestion('Zähle die Sterne', '⭐ ⭐', ['2', '3', '1'], 0, 'Zwei Sterne.');
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
    final mia = c.child.id;
    final strokes = [DrawStroke(color: 0xff278df4, width: .015,
      points: const [DrawPoint(.2, .3), DrawPoint(.4, .6)])];
    await c.saveDrawing(0, strokes, childId: mia);
    final id = c.childDrawings.single.id;
    await c.saveDrawing(0, strokes, childId: mia, drawingId: id);
    expect(c.childDrawings.length, 1);
    await expectLater(c.saveDrawing(1, strokes, childId: mia), throwsStateError);
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

  testWidgets('A full quiz grants one discovery sticker and no task stars', (tester) async {
    await c.activatePro(code);
    await tester.pumpWidget(MaterialApp(theme: fluffTheme(),
      home: LearningGamePage(controller: c, game: 'count', factory: FixedFactory())));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.ensureVisible(find.text('2'));
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey('next-question'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('Entdeckt!'), findsOneWidget);
    expect(c.gameCount('count'), 1);
    expect(c.balance(), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Drawing works and fits a small display with large text', (tester) async {
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

  testWidgets('Render real v5 discovery and drawing previews', (tester) async {
    if (!const bool.fromEnvironment('RENDER_PREVIEWS')) return;
    await c.activatePro(code);
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    final dir = Directory('previews/v5')..createSync(recursive: true);
    for (final item in <(String, Widget)>[
      ('Entdeckerwelt', Scaffold(body: DiscoveryPage(controller: c))),
      ('Malatelier', CreativeStudioPage(controller: c)),
      ('Paare-finden', LearningGamePage(controller: c, game: 'memory')),
      ('Sterne-zaehlen', LearningGamePage(controller: c, game: 'count')),
      ('Ausmalen', DrawingPage(controller: c, template: 1)),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(theme: fluffTheme(), home:
        RepaintBoundary(key: key, child: item.$2)));
      await tester.pumpAndSettle();
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
