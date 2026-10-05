import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluffs_sternenwelt/data/controller.dart';
import 'package:fluffs_sternenwelt/services/audio.dart';
import 'package:fluffs_sternenwelt/screens/child_pages.dart';
import 'package:fluffs_sternenwelt/screens/extra_pages.dart';
import 'package:fluffs_sternenwelt/screens/parents_screen.dart';
import 'package:fluffs_sternenwelt/screens/statistics.dart';
import 'package:fluffs_sternenwelt/screens/task_flow.dart';
import 'package:fluffs_sternenwelt/widgets/common.dart';
import 'fixtures.dart';

const renderPreviews = bool.fromEnvironment('RENDER_PREVIEWS');
const renderAnimation = bool.fromEnvironment('RENDER_ANIMATION');
typedef Preview = ({
  String name,
  Widget Function() page,
  int? nav,
  bool scene,
  bool night,
  bool warm,
});
List<Preview> previews(AppController c) => [
  (
    name: '01-start',
    page: () => HomePage(controller: c, onStart: () => c.selectTab(1)),
    nav: 0,
    scene: true,
    night: false,
    warm: false,
  ),
  (
    name: '02-aufgaben',
    page: () => TasksPage(controller: c),
    nav: 1,
    scene: false,
    night: false,
    warm: false,
  ),
  (
    name: '03-geschafft',
    page: () => CelebrationPage(controller: c, task: c.dayTasks.first),
    nav: null,
    scene: true,
    night: true,
    warm: false,
  ),
  (
    name: '04-sternenglas',
    page: () => StarsPage(controller: c),
    nav: 2,
    scene: true,
    night: false,
    warm: false,
  ),
  (
    name: '05-missionen',
    page: () => MissionsPage(controller: c),
    nav: 1,
    scene: true,
    night: false,
    warm: false,
  ),
  (
    name: '06-gefuehle',
    page: () => FeelingsPage(controller: c),
    nav: 3,
    scene: false,
    night: false,
    warm: false,
  ),
  (
    name: '07-wunschkiste',
    page: () => WishlistPage(controller: c),
    nav: 2,
    scene: false,
    night: false,
    warm: false,
  ),
  (
    name: '08-abendroutine',
    page: () => EveningPage(controller: c),
    nav: 4,
    scene: true,
    night: true,
    warm: false,
  ),
  (
    name: '09-elternbereich',
    page: () => ParentHub(controller: c),
    nav: null,
    scene: false,
    night: false,
    warm: true,
  ),
  (
    name: '10-kinderprofile',
    page: () => ProfilesPage(controller: c),
    nav: null,
    scene: false,
    night: false,
    warm: true,
  ),
  (
    name: '11-tagesplan',
    page: () => DayPlanPage(controller: c, allowEdit: true),
    nav: null,
    scene: false,
    night: false,
    warm: true,
  ),
  (
    name: '12-statistiken',
    page: () => StatisticsPage(controller: c),
    nav: null,
    scene: false,
    night: false,
    warm: true,
  ),
];

Widget phone(
  AppController c,
  Preview preview,
  GlobalKey boundary, {
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: fluffTheme(),
  locale: const Locale('de', 'DE'),
  supportedLocales: const [Locale('de', 'DE')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 28, bottom: 14),
        textScaler: TextScaler.linear(textScale),
      ),
      child: RepaintBoundary(
        key: boundary,
        child: AnimatedBuilder(
          animation: c,
          builder: (context, _) => Stack(
            children: [
              if (preview.name == '03-geschafft')
                preview.page()
              else
                Scaffold(
                  body: WorldBackground(
                    scene: preview.scene,
                    night: preview.night,
                    bedtime: preview.name == '08-abendroutine',
                    warm: preview.warm,
                    child: SafeArea(
                      bottom: preview.nav == null,
                      child: preview.page(),
                    ),
                  ),
                  bottomNavigationBar: preview.nav == null
                      ? null
                      : ChildNavigationBar(
                          index: preview.nav!,
                          onSelect: c.selectTab,
                        ),
                ),
              Positioned(
                top: 7,
                left: 21,
                child: IgnorePointer(
                  child: Text(
                    '9:41',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none,
                      color: preview.night ? Colors.white : ink,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 7,
                right: 17,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        size: 13,
                        color: preview.night ? Colors.white : ink,
                      ),
                      Icon(
                        Icons.wifi_rounded,
                        size: 13,
                        color: preview.night ? Colors.white : ink,
                      ),
                      Icon(
                        Icons.battery_full_rounded,
                        size: 15,
                        color: preview.night ? Colors.white : ink,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

Future<void> capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
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
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
    FluffAudio.instance.enabled = false;
  });

  testWidgets(
    'All twelve real screens fit a phone and render bundled artwork',
    (tester) async {
      final c = await previewController();
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var warmed = false;
      for (final preview in previews(c)) {
        await tester.pumpWidget(phone(c, preview, key));
        await tester.pumpAndSettle();
        if (!warmed) {
          final context = tester.element(find.byType(HomePage));
          await tester.runAsync(() async {
            final manifest = await AssetManifest.loadFromAssetBundle(
              rootBundle,
            );
            for (final asset in manifest.listAssets().where(
              (name) => name.startsWith('assets/art/'),
            )) {
              await precacheImage(AssetImage(asset), context);
            }
          });
          await tester.pumpAndSettle();
          warmed = true;
        }
        expect(tester.takeException(), isNull, reason: preview.name);
        if (renderPreviews) {
          await capture(tester, key, 'previews/${preview.name}.png');
        }
      }
    },
  );

  testWidgets(
    'All screens remain usable at 320 pixels with twice the text size',
    (tester) async {
      final c = await previewController();
      final key = GlobalKey();
      tester.view.physicalSize = const Size(640, 1400);
      tester.view.devicePixelRatio = 2;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final pages = [
        ...previews(c),
        (
          name: 'tasks-manager',
          page: () => TaskManagerPage(controller: c),
          nav: null,
          scene: false,
          night: false,
          warm: true,
        ),
        (
          name: 'rewards-manager',
          page: () => RewardManagerPage(controller: c),
          nav: null,
          scene: false,
          night: false,
          warm: true,
        ),
        (
          name: 'settings',
          page: () => SettingsPage(controller: c),
          nav: null,
          scene: false,
          night: false,
          warm: true,
        ),
      ];
      for (final preview in pages) {
        await tester.pumpWidget(phone(c, preview, key, textScale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: preview.name);
      }
    },
  );

  testWidgets(
    'Fluff moves when enabled and stops when the parent disables motion',
    (tester) async {
      final c = await previewController(motion: true);
      final key = GlobalKey();
      final preview = previews(c).first;
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(phone(c, preview, key));
      await tester.pump(const Duration(milliseconds: 120));
      String transforms() => tester
          .widgetList<Transform>(find.byType(Transform))
          .map((w) => w.transform.toString())
          .join('|');
      final before = transforms();
      await tester.pump(const Duration(milliseconds: 420));
      expect(transforms(), isNot(before));
      if (renderAnimation) {
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/art/fluff-welcome.png'),
            tester.element(find.byType(HomePage)),
          );
          await precacheImage(
            const AssetImage('assets/art/day-world-v2.jpg'),
            tester.element(find.byType(HomePage)),
          );
        });
        for (var i = 0; i < 84; i++) {
          await tester.pump(const Duration(milliseconds: 67));
          await capture(
            tester,
            key,
            'previews/animation/frame-${i.toString().padLeft(3, '0')}.png',
          );
        }
      }
      await c.settings(motion: false);
      await tester.pumpAndSettle();
      final stopped = transforms();
      await tester.pump(const Duration(seconds: 1));
      expect(transforms(), stopped);
      expect(tester.takeException(), isNull);
    },
  );
}
