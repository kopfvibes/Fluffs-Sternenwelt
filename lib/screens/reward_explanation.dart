import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/companion.dart';
import '../data/controller.dart';
import '../data/models.dart';
import '../services/audio.dart';
import '../widgets/child_narration.dart';
import '../widgets/common.dart';

Future<void> explainReward(BuildContext context, AppController controller,
  RewardItem reward) async {
  final childId = controller.child.id;
  // Stop playback immediately, but never block opening a child screen on audio I/O.
  unawaited(FluffAudio.instance.stop());
  if (!context.mounted) return;
  final requested = await showDialog<bool>(context: context,
    builder: (_) => RewardExplanationDialog(controller: controller, reward: reward));
  await FluffAudio.instance.stop();
  if (requested == true && controller.child.id == childId && controller.data.sound) {
    FluffAudio.instance.narrate([
      'Dein Wunsch wartet jetzt auf deine Erwachsenen. Deine Sterne bleiben '
        'erst einmal in deinem Glas.',
    ], preferFluff: controller.proActive);
  }
}

class RewardExplanationDialog extends StatefulWidget {
  const RewardExplanationDialog({super.key, required this.controller, required this.reward});
  final AppController controller;
  final RewardItem reward;
  @override
  State<RewardExplanationDialog> createState() => _RewardExplanationDialogState();
}
class _RewardExplanationDialogState extends State<RewardExplanationDialog> {
  late final String childId;
  late int stage;
  bool preview = false, saving = false;
  bool get small => widget.controller.child.age <= 4;
  bool get available => widget.controller.child.id == childId;
  @override
  void initState() {
    super.initState();
    childId = widget.controller.child.id;
    stage = small ? 0 : 2;
    widget.controller.addListener(_changed);
  }
  void _changed() {
    if (!available) {
      FluffAudio.instance.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) Navigator.pop(context, false);
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
    final reward = c.data.rewards.firstWhere((r) => r.id == widget.reward.id,
      orElse: () => widget.reward);
    final math = RewardExplanation(balance: c.balance(childId), cost: reward.cost,
      title: reward.title);
    final showingAfter = math.affordable && (preview || (small && stage == 2));
    final lines = !small || stage == 2 ? math.narration : stage == 0
      ? [...balanceNarration(math.balance), 'Dein Wunsch heißt:', reward.title,
        'Tippe auf Weiter. Wir schauen zusammen, was dein Wunsch kostet.']
      : [if (math.cost == 1) 'Dein Wunsch kostet einen Stern.'
          else ...['Dein Wunsch kostet', ...spokenNumber(math.cost), 'Sterne.'],
        'Diese Sterne würden wir für deinen Wunsch aus dem Glas nehmen.',
        'Tippe auf Weiter. Dann schauen wir, wie viele Sterne bleiben.'];
    return Dialog(backgroundColor: cream, insetPadding: const EdgeInsets.all(14),
      child: SizedBox(width: 440, height: min(720, MediaQuery.sizeOf(context).height * .9),
        child: ChildNarration(controller: c,
          identity: 'reward-$childId-${reward.cost}-${math.balance}-$stage-$preview',
          intro: lines,
          child: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            children: [
              Row(children: [Expanded(child: Text(reward.title,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
                IconButton(tooltip: 'Schließen', onPressed: saving ? null
                  : () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded))]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ArtIcon(reward.icon, size: 70),
                FluffSprite(size: 130, animate: c.data.motion),
              ]),
              if (!small || stage == 2)
                Row(children: [
                  _amount('Jetzt', math.balance),
                  Icon(math.affordable ? Icons.remove_rounded : Icons.add_rounded, color: blue),
                  _amount(math.affordable ? 'Für den Wunsch' : 'Fehlen noch',
                    math.affordable ? math.cost : math.missing),
                  const Icon(Icons.arrow_forward_rounded, color: blue),
                  _amount(math.affordable ? 'Danach' : 'Für den Wunsch',
                    math.affordable ? math.remaining : math.cost),
                ]),
              SizedBox(height: 215, child: Center(child: StarJar(
                count: showingAfter ? math.remaining : math.balance, animate: c.data.motion))),
              Text(showingAfter ? 'So sähe dein Glas nach dem Einlösen aus.'
                : 'So viele Sterne hast du jetzt.', textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GlossyPanel(child: Text(small && stage == 0
                ? 'Du hast ${math.balance} ${starWord(math.balance)}.'
                : small && stage == 1
                  ? 'Dein Wunsch kostet ${math.cost} ${starWord(math.cost)}.'
                  : math.summary,
                key: const ValueKey('reward-math-summary'),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              const SizedBox(height: 12),
              if (small && stage < 2)
                GlossyButton('Weiter', key: const ValueKey('reward-explain-next'),
                  icon: Icons.arrow_forward_rounded, onPressed: () => setState(() => stage++))
              else ...[
                if (math.affordable) ...[
                  if (!small) GlossyButton(preview ? 'Mein Glas jetzt zeigen' : 'Fluff zeigt es mir',
                    key: const ValueKey('reward-preview'), color: gold,
                    icon: Icons.star_rounded, onPressed: () => setState(() => preview = !preview)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Wir fragen zuerst deine Erwachsenen. Deine Sterne bleiben '
                      'bis zum Einlösen im Glas.', textAlign: TextAlign.center)),
                  GlossyButton('Wunsch anfragen', key: const ValueKey('request-reward'),
                    color: green, icon: Icons.card_giftcard_rounded,
                    onPressed: saving || c.busy || !available || !reward.active ? null : () async {
                      setState(() => saving = true);
                      try {
                        await c.requestReward(reward);
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (error) {
                        if (!mounted || !context.mounted) return;
                        setState(() => saving = false);
                        final message = error is StateError ? error.message.toString()
                          : 'Dein Wunsch konnte nicht gespeichert werden. Versuch es noch einmal.';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                        if (c.data.sound) { FluffAudio.instance.narrate([message],
                          preferFluff: c.proActive);
                        }
                      }
                    }),
                ] else
                  const Text('Du darfst in deinem Tempo weitersammeln.',
                    textAlign: TextAlign.center),
                TextButton(onPressed: saving ? null : () => Navigator.pop(context, false),
                  child: Text(math.affordable ? 'Abbrechen' : 'Okay')),
              ],
            ]))),
    );
  }
  Widget _amount(String label, int amount) => Expanded(child: Column(children: [
    Text('$amount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
  ]));
}
