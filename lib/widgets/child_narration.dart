import 'dart:async';
import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../services/audio.dart';
import '../services/child_routes.dart';
import 'common.dart';

/// Narration belongs to the visible route and selected child. Rebuilds while
/// saving cannot restart speech; leaving, changing children or muting stops it.
class ChildNarration extends StatefulWidget {
  const ChildNarration({super.key, required this.controller,
    required this.child, required this.intro, this.identity = '',
    this.onFluff, this.toolbar = true, this.autoRead = true});
  final AppController controller;
  final Widget child;
  final List<String> intro;
  final String identity;
  final VoidCallback? onFluff;
  final bool toolbar, autoRead;
  @override
  State<ChildNarration> createState() => _ChildNarrationState();
}

class _ChildNarrationState extends State<ChildNarration> with RouteAware {
  final contentKey = GlobalKey();
  late String childId;
  late bool sound, pro;
  int? ownRequest;
  ModalRoute<dynamic>? route;
  Timer? resumeTimer;
  @override
  void initState() {
    super.initState();
    _remember();
    widget.controller.addListener(_changed);
    _schedule();
  }
  void _remember() {
    childId = widget.controller.child.id;
    sound = widget.controller.data.sound;
    pro = widget.controller.proActive;
  }
  void _changed() {
    final changedChild = childId != widget.controller.child.id;
    final muted = sound && !widget.controller.data.sound;
    final lostPro = pro && !widget.controller.proActive;
    if (changedChild || muted || lostPro) FluffAudio.instance.stop();
    final enabled = !sound && widget.controller.data.sound;
    _remember();
    if (changedChild || enabled) _schedule();
  }
  bool get visible => mounted && (ModalRoute.of(context)?.isCurrent ?? true);
  void _schedule() {
    if (!widget.autoRead) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (visible) speak(widget.intro);
    });
  }
  @override
  void didUpdateWidget(ChildNarration old) {
    super.didUpdateWidget(old);
    if (old.identity != widget.identity) {
      FluffAudio.instance.stop();
      _schedule();
    }
  }
  void speak(Iterable<String> lines) {
    if (!visible || !widget.controller.data.sound) return;
    FluffAudio.instance.enabled = true;
    unawaited(FluffAudio.instance.narrate(lines,
      preferFluff: widget.controller.proActive));
    ownRequest = FluffAudio.instance.requestId;
  }
  void readPage() {
    final root = contentKey.currentContext;
    if (root == null) return;
    final lines = <String>[];
    void visit(Element element) {
      final w = element.widget;
      if (w is Offstage && w.offstage) return;
      if (w is Text) {
        final text = w.data ?? w.textSpan?.toPlainText() ?? '';
        if (text.trim().isNotEmpty && (lines.isEmpty || lines.last != text)) {
          lines.add(text);
        }
      }
      element.visitChildren(visit);
    }
    (root as Element).visitChildren(visit);
    speak(lines.isEmpty ? widget.intro : lines);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.of(context);
    if (current != route && current != null) {
      childRouteObserver.unsubscribe(this);
      route = current;
      childRouteObserver.subscribe(this, current);
    }
  }
  @override
  void didPushNext() {
    resumeTimer?.cancel();
    if (ownRequest == FluffAudio.instance.requestId) FluffAudio.instance.stop();
  }
  @override
  void didPopNext() {
    resumeTimer?.cancel();
    resumeTimer = Timer(const Duration(milliseconds: 380), _schedule);
  }
  @override
  void dispose() {
    resumeTimer?.cancel();
    childRouteObserver.unsubscribe(this);
    widget.controller.removeListener(_changed);
    if (ownRequest == FluffAudio.instance.requestId) FluffAudio.instance.stop();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FluffInteractionScope(
    onTap: widget.onFluff ?? () => speak(widget.intro),
    child: Column(children: [
      if (widget.toolbar)
        Padding(padding: const EdgeInsets.fromLTRB(16, 2, 12, 0),
          child: Row(children: [
            Expanded(child: TextButton.icon(
              key: const ValueKey('read-child-page'),
              onPressed: widget.controller.data.sound ? readPage : null,
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Alles anhören'),
            )),
            IconButton(tooltip: 'Fluff erklärt es noch einmal',
              onPressed: widget.controller.data.sound ? () => speak(widget.intro) : null,
              icon: const Icon(Icons.replay_rounded, color: blue)),
            ValueListenableBuilder<bool>(valueListenable: FluffAudio.instance.speaking,
              builder: (_, talking, _) => IconButton(
                tooltip: talking ? 'Vorlesen stoppen' : 'Fluff antippen',
                onPressed: talking ? FluffAudio.instance.stop
                  : widget.onFluff ?? () => speak(widget.intro),
                icon: Icon(talking ? Icons.stop_circle_rounded : Icons.waving_hand_rounded,
                  color: talking ? blue : ink))),
          ])),
      if (widget.toolbar)
        ValueListenableBuilder<String?>(valueListenable: FluffAudio.instance.voiceProblem,
          builder: (_, problem, _) => problem == null ? const SizedBox.shrink()
            : Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Text(problem, style: const TextStyle(fontSize: 12)))),
      Expanded(child: KeyedSubtree(key: contentKey, child: widget.child)),
    ]),
  );
}

/// For scrolling sheets and small dialogs with unbounded height.
class AutoRead extends StatefulWidget {
  const AutoRead({super.key, required this.controller, required this.lines,
    required this.child, this.identity = ''});
  final AppController controller;
  final List<String> lines;
  final Widget child;
  final String identity;
  @override
  State<AutoRead> createState() => _AutoReadState();
}
class _AutoReadState extends State<AutoRead> {
  int? ownRequest;
  late String childId;
  late bool pro;
  @override
  void initState() {
    super.initState();
    childId = widget.controller.child.id;
    pro = widget.controller.proActive;
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => read());
  }
  void _changed() {
    if (childId != widget.controller.child.id || !widget.controller.data.sound ||
        (pro && !widget.controller.proActive)) {
      if (ownRequest == FluffAudio.instance.requestId) FluffAudio.instance.stop();
    }
    pro = widget.controller.proActive;
  }
  void read() {
    if (!mounted || childId != widget.controller.child.id ||
        !widget.controller.data.sound || !(ModalRoute.of(context)?.isCurrent ?? true)) { return; }
    FluffAudio.instance.narrate(widget.lines, preferFluff: widget.controller.proActive);
    ownRequest = FluffAudio.instance.requestId;
  }
  @override
  void didUpdateWidget(AutoRead old) {
    super.didUpdateWidget(old);
    if (old.identity != widget.identity) {
      WidgetsBinding.instance.addPostFrameCallback((_) => read());
    }
  }
  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    if (ownRequest == FluffAudio.instance.requestId) FluffAudio.instance.stop();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FluffInteractionScope(onTap: read, child: widget.child);
}

/// A repeat button can read a particular row without triggering its action.
class HearButton extends StatelessWidget {
  const HearButton({super.key, required this.controller, required this.lines,
    this.label = 'Anhören'});
  final AppController controller;
  final List<String> lines;
  final String label;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    onPressed: controller.data.sound ? () => FluffAudio.instance.narrate(lines,
      preferFluff: controller.proActive) : null,
    icon: const Icon(Icons.volume_up_rounded, color: blue),
  );
}
