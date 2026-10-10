import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../widgets/common.dart';
import '../services/audio.dart';
import 'child_pages.dart';
import '../data/companion.dart';
import '../widgets/child_narration.dart';
import 'fluff_day.dart';

class ChildShell extends StatefulWidget {
  const ChildShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int get index => widget.controller.tab;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: WorldBackground(
      scene: index == 0 || index == 2,
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            final page = [
              HomePage(controller: c, onStart: () => c.selectTab(1)),
              TasksPage(controller: c),
              StarsPage(controller: c),
              FeelingsPage(controller: c),
              MorePage(controller: c),
            ][index];
            return ChildNarration(controller: c,
              identity: '${c.child.id}|$index|${c.today}',
              intro: childScreenNarration(c, index),
              onFluff: () => showFluffDay(context, c), child: page);
          },
        ),
      ),
    ),
    bottomNavigationBar: ChildNavigationBar(
      index: index,
      onSelect: (i) {
        FluffAudio.instance.stop();
        widget.controller.selectTab(i);
      },
    ),
  );
}
