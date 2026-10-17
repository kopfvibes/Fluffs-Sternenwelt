import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/companion.dart';
import '../data/controller.dart';
import '../services/audio.dart';
import '../widgets/child_narration.dart';
import '../widgets/common.dart';
import 'task_flow.dart';

Future<void> showFluffDay(BuildContext context, AppController controller) async {
  // Stop playback immediately, but never block opening a child screen on audio I/O.
  unawaited(FluffAudio.instance.stop());
  if (!context.mounted) return;
  await showDialog<void>(context: context,
    builder: (_) => FluffDayDialog(controller: controller));
  await FluffAudio.instance.stop();
}

class FluffDayDialog extends StatefulWidget {
  const FluffDayDialog({super.key, required this.controller});
  final AppController controller;
  @override
  State<FluffDayDialog> createState() => _FluffDayDialogState();
}
class _FluffDayDialogState extends State<FluffDayDialog> {
  late final String childId;
  int storyStep = -1;
  bool waving = false;
  @override
  void initState() {
    super.initState();
    childId = widget.controller.child.id;
    widget.controller.addListener(_changed);
  }
  void _changed() {
    if (mounted && widget.controller.child.id != childId) {
      FluffAudio.instance.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.pop(context);
        }
      });
    } else if (mounted) { setState(() {}); }
  }
  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final story = fluffStories[(c.now.difference(DateTime(c.now.year)).inDays) % fluffStories.length];
    final telling = storyStep >= 0;
    final next = nextDayTasks(c);
    final lines = telling ? [story.steps[storyStep]] : waving
      ? ['Hallo! Ich winke dir zu. Magst du zurückwinken?'] : dayNarration(c);
    return Dialog(backgroundColor: cream, insetPadding: const EdgeInsets.all(16),
      child: SizedBox(width: 430, height: min(680, MediaQuery.sizeOf(context).height * .86),
        child: ChildNarration(controller: c,
          identity: 'day-$childId-$storyStep-$waving', intro: lines,
          onFluff: () {
            setState(() => waving = !waving);
          },
          child: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            children: [
              Row(children: [
                Expanded(child: Text(telling ? story.title : 'Dein Tag mit Fluff',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                IconButton(tooltip: 'Schließen',
                  onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
              Center(child: FluffSprite(pose: waving ? 'welcome' : 'idle',
                size: 210, animate: c.data.motion,
                onTap: () => setState(() => waving = !waving))),
              GlossyPanel(child: Text(telling ? story.steps[storyStep]
                : waving ? 'Hallo! Magst du zurückwinken?'
                : 'Ich helfe dir. Wir machen einen kleinen Schritt nach dem anderen.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              const SizedBox(height: 12),
              if (telling) ...[
                GlossyButton(storyStep + 1 < story.steps.length ? 'Weiter erzählen' : 'Zurück zu meinem Tag',
                  key: const ValueKey('fluff-story-next'), icon: Icons.arrow_forward_rounded,
                  onPressed: () => setState(() {
                    storyStep = storyStep + 1 < story.steps.length ? storyStep + 1 : -1;
                    waving = false;
                  })),
              ] else ...[
                Text('${c.balance()} ${starWord(c.balance())} in deinem Glas',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                for (final task in next.take(c.child.age <= 4 ? 1 : 3))
                  Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlossyPanel(onTap: () {
                      final ownerContext = Navigator.of(context).context;
                      Navigator.pop(context);
                      openTask(ownerContext, c, task);
                    }, child: Row(children: [ArtIcon(task.icon, size: 54),
                      const SizedBox(width: 10), Expanded(child: Text(task.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                      HearButton(controller: c, lines: [task.title, ...task.steps]),
                    ]))),
                if (next.isNotEmpty)
                  GlossyButton('Mit dieser Aufgabe anfangen', icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      final ownerContext = navigator.context;
                      Navigator.pop(context);
                      openTask(ownerContext, c, next.first);
                    }),
                if (next.isEmpty)
                  const Text('Jetzt ist Zeit für Spielen und Pausen.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GlossyButton('Fluffs Geschichte hören', key: const ValueKey('fluff-story'),
                  icon: Icons.menu_book_rounded, color: gold,
                  onPressed: () => setState(() { storyStep = 0; waving = false; })),
                const SizedBox(height: 12),
                GlossyButton('Zusammen winken', key: const ValueKey('fluff-wave'),
                  icon: Icons.waving_hand_rounded, color: green,
                  onPressed: () => setState(() => waving = !waving)),
              ],
              const SizedBox(height: 8),
              TextButton.icon(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded), label: const Text('Fertig')),
            ]))),
    );
  }
}
