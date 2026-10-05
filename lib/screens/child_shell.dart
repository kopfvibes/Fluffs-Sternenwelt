import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../widgets/common.dart';
import '../services/audio.dart';
import 'child_pages.dart';

class ChildShell extends StatefulWidget {
  const ChildShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int get index => widget.controller.tab;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FluffAudio.instance.say('welcome');
    });
  }

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
            return [
              HomePage(controller: c, onStart: () => c.selectTab(1)),
              TasksPage(controller: c),
              StarsPage(controller: c),
              FeelingsPage(controller: c),
              MorePage(controller: c),
            ][index];
          },
        ),
      ),
    ),
    bottomNavigationBar: ChildNavigationBar(
      index: index,
      onSelect: (i) {
        FluffAudio.instance.stop();
        if (i == 2) FluffAudio.instance.say('stars');
        widget.controller.selectTab(i);
      },
    ),
  );
}
