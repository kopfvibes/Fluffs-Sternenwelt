import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/controller.dart';
import '../data/models.dart';
import '../services/audio.dart';
import '../widgets/common.dart';
import 'task_flow.dart';
import 'extra_pages.dart';
import 'parents_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller, required this.onStart});
  final AppController controller;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, b) {
      final hero = (b.maxHeight - 207).clamp(290.0, 620.0);
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        children: [
          SizedBox(
            height: hero,
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  left: 9,
                  right: 9,
                  child: Image.asset(
                    'assets/art/logo.png',
                    height: hero * .30,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: hero * .27,
                  left: -15,
                  right: -15,
                  bottom: -10,
                  child: Center(
                    child: FluffSprite(
                      pose: 'welcome',
                      size: hero * .81,
                      animate: controller.data.motion,
                      onTap: () => FluffAudio.instance.say('welcome'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GlossyPanel(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(20, 13, 20, 14),
            onTap: () => chooseChild(context, controller),
            child: Column(
              children: [
                Text(
                  'Hallo ${controller.child.name}!',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Schön, dass du da bist!\nWas möchtest du heute\ngemeinsam schaffen?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          GlossyButton(
            'Los geht’s!',
            icon: Icons.arrow_forward_rounded,
            key: const ValueKey('start-tasks'),
            onPressed: onStart,
          ),
        ],
      );
    },
  );
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle('Heute', controller: controller),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            DateFormat('EEEE, d. MMMM', 'de_DE').format(controller.now),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(19, 6, 19, 10),
        child: ProgressStrip(
          done: controller.completed,
          total: controller.dayTasks.length,
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(19, 2, 19, 18),
          children: [
            if (controller.dayTasks.isEmpty)
              const GlossyPanel(
                child: Text(
                  'Heute ist Zeit für freie Abenteuer. Deine Erwachsenen können Aufgaben im Elternbereich einstellen.',
                ),
              ),
            for (final task in controller.dayTasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: TaskRow(
                  task: task,
                  done: controller.done(task),
                  onTap: () => openTask(context, controller, task),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.done,
    required this.onTap,
    this.compact = false,
  });
  final TaskItem task;
  final bool done, compact;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GlossyPanel(
    key: ValueKey('task-${task.id}'),
    radius: 18,
    color: done ? const Color(0xffe8f9de) : null,
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 7 : 10),
    onTap: onTap,
    child: Row(
      children: [
        ArtIcon(task.icon, size: compact ? 38 : 45),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
        ),
        const SizedBox(width: 8),
        DoneCircle(done, size: 29),
      ],
    ),
  );
}

class StarsPage extends StatelessWidget {
  const StarsPage({super.key, required this.controller});
  final AppController controller;
  int count(String type) => controller.data.stars
      .where(
        (e) =>
            e.childId == controller.child.id && e.amount > 0 && e.type == type,
      )
      .fold(0, (n, e) => n + e.amount);

  Widget _counter(String icon, int value, String label) => Row(
    children: [
      if (icon == 'week')
        const Icon(Icons.bar_chart_rounded, color: blue, size: 36)
      else
        ArtIcon(icon, size: 36),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _counters() => GlossyPanel(
    radius: 25,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 18),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _counter('star', controller.balance(), 'Sterne gesamt'),
        const SizedBox(height: 24),
        _counter(
          'week',
          controller.earnedSince(monday(controller.now)),
          'Diese Woche',
        ),
        const SizedBox(height: 24),
        _counter('heart', count('mut'), 'Mutsterne'),
        const SizedBox(height: 24),
        _counter('help', count('hilfe'), 'Hilfssterne'),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      children: [
        const ScreenTitle('Mein Sternenglas'),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                if (largeText) ...[
                  SizedBox(
                    height: 340,
                    child: Center(
                      child: StarJar(
                        count: controller.balance(),
                        animate: controller.data.motion,
                      ),
                    ),
                  ),
                  _counters(),
                  const SizedBox(height: 16),
                ] else
                  SizedBox(
                    height: (bounds.maxHeight * .63).clamp(315.0, 480.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: StarJar(
                            count: controller.balance(),
                            animate: controller.data.motion,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(flex: 4, child: _counters()),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: FluffSprite(
                        pose: 'sitting',
                        size: 180,
                        animate: controller.data.motion,
                      ),
                    ),
                    const Expanded(
                      flex: 6,
                      child: GlossyPanel(
                        radius: 26,
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Wow!\nDu sammelst fleißig\nSterne! Weiter so!',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                GlossyButton(
                  'Meine Wunschkiste',
                  small: true,
                  icon: Icons.card_giftcard_rounded,
                  onPressed: () => openChildPage(
                    context,
                    controller,
                    () => WishlistPage(controller: controller),
                    index: 2,
                  ),
                ),
                const SizedBox(height: 9),
                GlossyPanel(
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: const Text(
                      'Meine Sterne ansehen',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    children: [
                      if (!controller.data.stars.any(
                        (e) => e.childId == controller.child.id,
                      ))
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('Dein erster Stern wartet auf dich.'),
                        ),
                      for (final e
                          in controller.data.stars
                              .where((e) => e.childId == controller.child.id)
                              .toList()
                              .reversed
                              .take(8))
                        ListTile(
                          dense: true,
                          leading: Icon(
                            e.amount > 0
                                ? Icons.star_rounded
                                : Icons.card_giftcard_rounded,
                            color: gold,
                          ),
                          title: Text(e.label),
                          subtitle: Text(
                            DateFormat(
                              'd. MMMM',
                              'de_DE',
                            ).format(DateTime.parse(e.date)),
                          ),
                          trailing: Text(
                            '${e.amount > 0 ? '+' : ''}${e.amount}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FeelingsPage extends StatelessWidget {
  const FeelingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const ScreenTitle(
        'Wie fühlst du dich?',
        subtitle: 'Tippe an, wie du dich gerade fühlst.',
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, b) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final height = ((b.maxHeight - 18) / 3).clamp(135.0, 172.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 11,
                childAspectRatio:
                    ((b.maxWidth - 45) / 2) / (height * scale.clamp(1.0, 1.5)),
                children: List.generate(6, (i) {
                  const labels = [
                    'glücklich',
                    'traurig',
                    'wütend',
                    'unsicher',
                    'müde',
                    'stolz',
                  ];
                  const poses = [
                    'idle',
                    'sad',
                    'angry',
                    'unsure',
                    'tired',
                    'proud',
                  ];
                  const colors = [
                    Color(0xffffedac),
                    Color(0xffc9e3fe),
                    Color(0xffffc8cc),
                    Color(0xffe1cefc),
                    Color(0xffbfe5ff),
                    Color(0xffd8f7a9),
                  ];
                  final selected = controller.currentFeeling == labels[i];
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: labels[i],
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[i],
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: selected ? blue : Colors.white,
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x130a2452),
                            offset: Offset(0, 3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        child: InkWell(
                          key: ValueKey('feeling-${labels[i]}'),
                          borderRadius: BorderRadius.circular(26),
                          onTap: () => showFeeling(
                            context,
                            controller,
                            labels[i],
                            poses[i],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  child: OverflowBox(
                                    maxHeight: height * .95,
                                    minHeight: height * .95,
                                    alignment: Alignment.bottomCenter,
                                    child: FluffSprite(
                                      pose: poses[i],
                                      size: height * .97,
                                      animate: controller.data.motion,
                                      faceOnly: true,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 1,
                                  bottom: 11,
                                ),
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Future<void> showFeeling(
  BuildContext context,
  AppController controller,
  String value,
  String pose,
) async {
  await act(context, () => controller.setFeeling(value));
  if (!context.mounted) return;
  FluffAudio.instance.say(value);
  const messages = {
    'glücklich': 'Wie schön! Magst du erzählen, was dir gerade Freude macht?',
    'traurig':
        'Traurig sein ist okay. Du musst nichts schaffen. Such dir jemanden zum Kuscheln oder Reden.',
    'wütend':
        'Wut darf da sein. Stell deine Füße auf den Boden. Drück ein Kissen und atme langsam aus.',
    'unsicher':
        'Du darfst einen kleinen Schritt probieren oder einen Erwachsenen um Hilfe bitten.',
    'müde': 'Dein Körper braucht vielleicht Ruhe. Eine Pause ist okay.',
    'stolz':
        'Du hast etwas ausprobiert oder geschafft. Erzähl, worauf du stolz bist.',
  };
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: cream,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluffSprite(pose: pose, size: 190, animate: controller.data.motion),
            Text(
              'Du fühlst dich $value.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              messages[value]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'Jedes Gefühl darf da sein.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GlossyButton('Okay', onPressed: () => Navigator.pop(sheet)),
            if (value == 'wütend' || value == 'unsicher')
              TextButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  openChildPage(
                    context,
                    controller,
                    () => BreathingPage(controller: controller),
                    index: 3,
                  );
                },
                child: const Text('Gemeinsam ruhig atmen'),
              ),
          ],
        ),
      ),
    ),
  );
}

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle('Mehr Sternenwelt', controller: controller),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(19, 0, 19, 20),
          children: [
            for (final item in <(String, String, VoidCallback)>[
              (
                'Fluffs Missionen',
                'bag',
                () => openChildPage(
                  context,
                  controller,
                  () => MissionsPage(controller: controller),
                  index: 1,
                ),
              ),
              (
                'Meine Wunschkiste',
                'gift',
                () => openChildPage(
                  context,
                  controller,
                  () => WishlistPage(controller: controller),
                  index: 2,
                ),
              ),
              (
                'Abendroutine',
                'moon',
                () => openChildPage(
                  context,
                  controller,
                  () => EveningPage(controller: controller),
                  index: 4,
                  night: true,
                ),
              ),
              (
                'Mein Tagesplan',
                'calendar',
                () => openChildPage(
                  context,
                  controller,
                  () => DayPlanPage(controller: controller),
                  index: 4,
                ),
              ),
              (
                'Gemeinsam ruhig atmen',
                'moon',
                () => openChildPage(
                  context,
                  controller,
                  () => BreathingPage(controller: controller),
                  index: 3,
                ),
              ),
              (
                'Elternbereich',
                'clipboard',
                () => openParents(context, controller),
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: GlossyPanel(
                  onTap: item.$3,
                  child: Row(
                    children: [
                      ArtIcon(item.$2, size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Center(
              child: FluffSprite(size: 165, animate: controller.data.motion),
            ),
            const Text(
              'Kleine Aufgaben. Große Schritte.\nMit Fluff an deiner Seite.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> openChildPage(
  BuildContext context,
  AppController controller,
  Widget Function() page, {
  int index = 4,
  bool night = false,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final selected = page();
          return Scaffold(
            body: WorldBackground(
              scene: night || selected is MissionsPage,
              night: night,
              bedtime: selected is EveningPage,
              child: SafeArea(bottom: false, child: selected),
            ),
            bottomNavigationBar: ChildNavigationBar(
              index: index,
              onSelect: (i) {
                controller.selectTab(i);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          );
        },
      ),
    ),
  );
}
