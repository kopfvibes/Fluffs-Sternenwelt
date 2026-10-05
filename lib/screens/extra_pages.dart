import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/controller.dart';
import '../data/models.dart';
import '../services/audio.dart';
import '../widgets/common.dart';
import 'task_flow.dart';

class MissionsPage extends StatelessWidget {
  const MissionsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle('Fluffs Missionen', leading: Icons.star_rounded),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 18),
          children: [
            SizedBox(
              height: 270,
              child: Stack(
                children: [
                  Positioned(
                    left: -22,
                    top: -8,
                    bottom: 0,
                    right: 60,
                    child: FluffSprite(
                      pose: 'explorer',
                      size: 292,
                      animate: controller.data.motion,
                      onTap: () => FluffAudio.instance.say('mission'),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 18,
                    width: 142,
                    child: const GlossyPanel(
                      radius: 25,
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Gemeinsam\nneue Abenteuer\nerleben!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final key in ['helper', 'reading', 'courage'])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _missionCard(context, key),
              ),
          ],
        ),
      ),
    ],
  );
  Widget _missionCard(BuildContext context, String key) {
    final done = controller.missionProgress(key),
        target = controller.missionTarget(key),
        claimed = controller.missionClaimed(key);
    final text = key == 'helper'
        ? 'Hilf zu Hause mit und erledige mindestens 3 Aufgaben.'
        : key == 'reading'
        ? 'Lies an 3 Tagen in dieser Woche je 10 Minuten. Vorlesen zählt.'
        : 'Hol dir bei einer Aufgabe Hilfe. Gemeinsam schaffen zählt.';
    return GlossyPanel(
      radius: 24,
      padding: const EdgeInsets.all(13),
      onTap: () => _openMission(context, key),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (key == 'helper')
            SizedBox(
              width: 61,
              height: 61,
              child: ClipOval(
                child: Container(
                  color: const Color(0xffbbe8ff),
                  child: const FluffSprite(
                    pose: 'explorer',
                    size: 62,
                    animate: false,
                  ),
                ),
              ),
            )
          else
            ArtIcon(key == 'reading' ? 'book' : 'moon', size: 57),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.missionLabel(key),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(text, style: const TextStyle(fontSize: 14, height: 1.2)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: gold, size: 28),
                    Flexible(
                      child: Text(
                        '${controller.missionStars(key)} Sterne',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: min(done / target, 1),
                          color: green,
                          backgroundColor: const Color(0xffe2e3e2),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${min(done, target)}/$target',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (claimed)
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text(
                      'Bonus schon gesammelt',
                      style: TextStyle(
                        color: Color(0xff058536),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMission(
    BuildContext context,
    String key,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: cream,
    builder: (sheet) => SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FluffSprite(
                pose: key == 'reading' ? 'proud' : 'explorer',
                size: 180,
                animate: controller.data.motion,
              ),
              Text(
                controller.missionLabel(key),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                key == 'reading'
                    ? 'Such dir an drei verschiedenen Tagen ein Buch aus. Lies selbst oder lass dir vorlesen. Deine Lese-Aufgaben zählen automatisch.'
                    : key == 'helper'
                    ? 'Räume deinen Frühstücksplatz ab, hilf beim Tischdecken oder räume eine kleine Ecke auf. Drei Helfer-Aufgaben an einem Tag erfüllen diese Mission.'
                    : 'Wenn etwas schwierig ist, frag einen Erwachsenen nach Hilfe. Aktiviere bei einer Aufgabe „Ich habe Hilfe bekommen“.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 18),
              ProgressStrip(
                done: min(
                  controller.missionProgress(key),
                  controller.missionTarget(key),
                ),
                total: controller.missionTarget(key),
                caption: false,
              ),
              const SizedBox(height: 18),
              if (controller.missionProgress(key) >=
                      controller.missionTarget(key) &&
                  !controller.missionClaimed(key))
                GlossyButton(
                  '${controller.missionStars(key)} Bonussterne sammeln',
                  color: green,
                  onPressed: controller.busy
                      ? null
                      : () => act(sheet, () async {
                          await controller.claimMission(key);
                          FluffAudio.instance.star();
                          if (sheet.mounted) Navigator.pop(sheet);
                        }),
                )
              else
                GlossyButton(
                  controller.missionClaimed(key)
                      ? 'Bonus schon gesammelt'
                      : 'Zu meinen Aufgaben',
                  onPressed: () {
                    Navigator.of(sheet).popUntil((r) => r.isFirst);
                    controller.selectTab(1);
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle(
        'Meine Wunschkiste',
        leading: Icons.star_rounded,
        subtitle: 'Sammle Sterne und erfülle dir\ndeine Wünsche!',
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 22),
          children: [
            for (final reward in controller.data.rewards.where((r) => r.active))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlossyPanel(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 12,
                  ),
                  onTap: () => _wish(context, reward),
                  child: Row(
                    children: [
                      ArtIcon(reward.icon, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reward.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: gold, size: 27),
                      Text(
                        '${reward.cost} Sterne',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (controller.data.rewards.every((r) => !r.active))
              const GlossyPanel(
                child: Text(
                  'Deine Erwachsenen können gemeinsame Wünsche im Elternbereich anlegen.',
                ),
              ),
            for (final request in controller.data.requests.where(
              (r) => r.childId == controller.child.id && r.status == 'offen',
            ))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GlossyPanel(
                  onTap: () => _pending(context, request),
                  color: const Color(0xffe5d8ff),
                  child: Text(
                    '${request.title}\nWartet auf Elternfreigabe',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
  Future<void> _pending(
    BuildContext context,
    WishRequest request,
  ) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(request.title),
      content: const Text(
        'Deine Erwachsenen entscheiden gemeinsam mit dir. Du kannst deinen Wunsch auch zurückziehen.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Okay'),
        ),
        TextButton(
          onPressed: () => act(dialog, () async {
            await controller.decideRequest(request.id, 'zurückgezogen');
            if (dialog.mounted) Navigator.pop(dialog);
          }),
          child: const Text('Zurückziehen'),
        ),
      ],
    ),
  );
  Future<void> _wish(BuildContext context, RewardItem reward) async {
    final existing = controller.data.requests.where(
      (x) =>
          x.rewardId == reward.id &&
          x.childId == controller.child.id &&
          x.status == 'offen',
    );
    if (existing.isNotEmpty) {
      await _pending(context, existing.first);
      return;
    }
    final remaining = reward.cost - controller.balance();
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(reward.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArtIcon(reward.icon, size: 85),
            const SizedBox(height: 12),
            Text(
              remaining > 0
                  ? 'Dafür fehlen noch $remaining Sterne. Sammle in deinem Tempo weiter.'
                  : 'Du hast genug Sterne. Soll dieser Wunsch deinen Erwachsenen zur Freigabe angezeigt werden?',
            ),
            const SizedBox(height: 9),
            Text(
              '${controller.balance()} Sterne in deinem Glas',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(remaining > 0 ? 'Okay' : 'Abbrechen'),
          ),
          if (remaining <= 0)
            TextButton(
              onPressed: () => act(dialog, () async {
                await controller.requestReward(reward);
                if (dialog.mounted) Navigator.pop(dialog);
              }),
              child: const Text('Wunsch anfragen'),
            ),
        ],
      ),
    );
  }
}

class EveningPage extends StatelessWidget {
  const EveningPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle(
        'Abendroutine',
        leading: Icons.nightlight_round,
        night: true,
        subtitle: 'Gemeinsam entspannt in den Schlaf.',
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(19, 0, 19, 17),
          children: [
            GlossyPanel(
              radius: 23,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Column(
                children: [
                  for (final t in controller.eveningTasks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: InkWell(
                        onTap: () => openTask(context, controller, t),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            ArtIcon(t.icon, size: 41),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            DoneCircle(controller.done(t), size: 29),
                          ],
                        ),
                      ),
                    ),
                  if (controller.eveningTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Heute gibt es keinen festen Abendplan. Macht es euch gemeinsam gemütlich.',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 218,
              child: Stack(
                children: [
                  Positioned(
                    left: -35,
                    bottom: -22,
                    width: 270,
                    height: 230,
                    child: FluffSprite(
                      pose: 'sleeping',
                      size: 260,
                      animate: controller.data.motion,
                      onTap: () => FluffAudio.instance.say('bedtime'),
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 17,
                    width: 168,
                    child: GlossyPanel(
                      radius: 29,
                      padding: EdgeInsets.all(13),
                      child: Text(
                        'Du schaffst das!\nEine gute Nacht\nfür süße Träume!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class DayPlanPage extends StatefulWidget {
  const DayPlanPage({
    super.key,
    required this.controller,
    this.allowEdit = false,
    this.onEditPlan,
  });
  final AppController controller;
  final bool allowEdit;
  final ValueChanged<PlanItem>? onEditPlan;
  @override
  State<DayPlanPage> createState() => _DayPlanPageState();
}

class _DayPlanPageState extends State<DayPlanPage> {
  late DateTime selected;
  @override
  void initState() {
    super.initState();
    selected = dateOnly(widget.controller.now);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final week = monday(selected);
    final rows =
        <
          ({
            String time,
            String title,
            String icon,
            bool done,
            TaskItem? task,
            PlanItem? plan,
          })
        >[];
    for (final p in c.data.plans.where((p) => p.active)) {
      rows.add((
        time: p.time,
        title: p.title,
        icon: p.icon,
        done: c.planDone(p, selected),
        task: null,
        plan: p,
      ));
    }
    for (final t in c.tasksOn(selected).where((t) => t.showInPlan)) {
      rows.add((
        time: t.time,
        title: t.title,
        icon: t.icon,
        done: c.done(t, date: dateKey(selected)),
        task: t,
        plan: null,
      ));
    }
    rows.sort((a, b) => a.time.compareTo(b.time));
    final isToday = dateKey(selected) == c.today;
    return Column(
      children: [
        ScreenTitle(
          'Tagesplan',
          back: () => Navigator.maybePop(context),
          trailing: widget.allowEdit
              ? IconButton(
                  tooltip: 'Planpunkt hinzufügen',
                  onPressed: () => widget.onEditPlan?.call(
                    PlanItem(id: '', title: '', icon: 'bed', time: '07:00'),
                  ),
                  icon: const Icon(Icons.add_rounded),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 0, 13, 15),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Vorige Woche',
                onPressed: () =>
                    setState(() => selected = addDays(selected, -7)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (i) {
                      final date = addDays(week, i);
                      final active = dateKey(date) == dateKey(selected);
                      return Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: InkWell(
                          onTap: () => setState(() => selected = date),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 48,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: active
                                    ? [const Color(0xff56caff), blue]
                                    : [
                                        const Color(0xfffffdf8),
                                        const Color(0xfffaf4e9),
                                      ],
                              ),
                              border: Border.all(color: Colors.white),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x110c3156),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: active ? Colors.white : ink,
                                  ),
                                ),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: active ? Colors.white : ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Nächste Woche',
                onPressed: () =>
                    setState(() => selected = addDays(selected, 7)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        if (!isToday)
          TextButton(
            onPressed: () => setState(() => selected = dateOnly(c.now)),
            child: Text(
              '${DateFormat('d. MMMM', 'de_DE').format(selected)} · zurück zu heute',
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(17, 0, 17, 23),
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: InkWell(
                    onLongPress: widget.allowEdit && row.plan != null
                        ? () => widget.onEditPlan?.call(row.plan!)
                        : null,
                    onTap: () => isToday
                        ? row.task != null
                              ? openTask(context, c, row.task!)
                              : act(context, () => c.togglePlan(row.plan!))
                        : ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Dieser Tag zeigt deinen Plan. Erledigen kannst du Aufgaben am jeweiligen Tag.',
                              ),
                            ),
                          ),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              row.time,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: const Color(0xffebcc7e),
                          ),
                          const SizedBox(width: 12),
                          ArtIcon(row.icon, size: 39),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              row.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          DoneCircle(row.done, size: 25),
                        ],
                      ),
                    ),
                  ),
                ),
              if (rows.isEmpty)
                const GlossyPanel(
                  child: Text('Für diesen Tag ist nichts fest eingeplant.'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController breath;
  @override
  void initState() {
    super.initState();
    breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = breath.value * 24;
    final phase = seconds % 8;
    final finished = breath.isCompleted;
    final scale = 1 + sin(phase / 8 * pi) * .15;
    return SingleChildScrollView(
      child: Column(
        children: [
          ScreenTitle(
            'Ruhig atmen',
            back: () => Navigator.maybePop(context),
            subtitle: 'Fluff macht mit. Du bestimmst das Tempo.',
          ),
          const SizedBox(height: 40),
          Transform.scale(
            scale: widget.controller.data.motion ? scale : 1,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffceebff),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(color: Color(0x551aa2ee), blurRadius: 25),
                ],
              ),
              child: FluffSprite(pose: 'blink', size: 235, animate: false),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            finished
                ? 'Gut gemacht. Zeit für eine Pause.'
                : !breath.isAnimating && breath.value == 0
                ? 'Mach es dir gemütlich.'
                : phase < 3
                ? 'Langsam einatmen'
                : phase < 4
                ? 'Einen Moment warten'
                : 'Langsam ausatmen',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 9),
          Text('${min((seconds / 8).floor() + 1, 3)} von 3 Atemrunden'),
          Padding(
            padding: const EdgeInsets.all(24),
            child: GlossyButton(
              finished
                  ? 'Noch einmal'
                  : breath.isAnimating
                  ? 'Pause'
                  : breath.value == 0
                  ? 'Starten'
                  : 'Fortsetzen',
              onPressed: () {
                if (finished) {
                  breath.value = 0;
                  breath.forward();
                } else if (breath.isAnimating) {
                  breath.stop();
                  setState(() {});
                } else {
                  breath.forward();
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 26),
            child: Text(
              'Du kannst jederzeit aufhören. Wenn du Trost brauchst, hol dir einen Erwachsenen.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
