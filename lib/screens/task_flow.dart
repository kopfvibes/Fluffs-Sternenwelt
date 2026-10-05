import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/controller.dart';
import '../data/models.dart';
import '../services/audio.dart';
import '../widgets/common.dart';

Future<void> openTask(
  BuildContext context,
  AppController controller,
  TaskItem first,
) async {
  TaskItem? task = first;
  while (task != null && context.mounted) {
    final item = task;
    final earned = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cream,
      builder: (sheet) => _TaskSheet(controller: controller, task: item),
    );
    if (earned != true || !context.mounted) return;
    final next = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CelebrationPage(controller: controller, task: item),
      ),
    );
    if (next != true || !context.mounted) return;
    final list = item.routine == 'Abend'
        ? controller.eveningTasks
        : controller.dayTasks;
    final remaining = list.where((t) => !controller.done(t));
    task = remaining.isEmpty ? null : remaining.first;
    if (task == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Für heute sind deine kleinen Aufgaben geschafft. Zeit für eine Pause!',
          ),
        ),
      );
    }
  }
}

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({required this.controller, required this.task});
  final AppController controller;
  final TaskItem task;
  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  bool assisted = false, saving = false;
  @override
  Widget build(BuildContext context) {
    final completed = widget.controller.done(widget.task);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArtIcon(widget.task.icon, size: 76),
            const SizedBox(height: 8),
            Text(
              widget.task.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < widget.task.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: gold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.task.steps[i],
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            GlossyPanel(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Ich habe Hilfe bekommen',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Gemeinsam schaffen zählt genauso.'),
                value: assisted,
                onChanged: completed || saving
                    ? null
                    : (v) => setState(() => assisted = v),
              ),
            ),
            const SizedBox(height: 16),
            GlossyButton(
              completed
                  ? 'Heute schon geschafft'
                  : 'Geschafft! + ${widget.task.stars} ${widget.task.stars == 1 ? 'Stern' : 'Sterne'}',
              color: green,
              key: const ValueKey('complete-task'),
              onPressed: completed || saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        final result = await widget.controller.completeTask(
                          widget.task,
                          assisted: assisted,
                        );
                        if (widget.controller.data.haptics) {
                          HapticFeedback.lightImpact();
                        }
                        if (context.mounted) Navigator.pop(context, result);
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e is StateError
                                    ? e.message
                                    : 'Die Aufgabe konnte nicht gespeichert werden.',
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Später weiter'),
            ),
          ],
        ),
      ),
    );
  }
}

class CelebrationPage extends StatefulWidget {
  const CelebrationPage({
    super.key,
    required this.controller,
    required this.task,
  });
  final AppController controller;
  final TaskItem task;
  @override
  State<CelebrationPage> createState() => _CelebrationPageState();
}

class _CelebrationPageState extends State<CelebrationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.controller.data.motion) animation.repeat();
    FluffAudio.instance.say('success');
    FluffAudio.instance.star();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _CelebrationBackground(
      child: Stack(
        children: [
          if (widget.controller.data.motion)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (_, _) =>
                      CustomPaint(painter: _Confetti(animation.value)),
                ),
              ),
            ),
          if (!widget.controller.data.motion)
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _Confetti(.13))),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, b) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                child: Column(
                  children: [
                    const Text(
                      'Geschafft!',
                      style: TextStyle(
                        fontSize: 43,
                        fontWeight: FontWeight.w900,
                        color: Color(0xffffdc72),
                        shadows: [
                          Shadow(
                            color: Color(0xffad6019),
                            offset: Offset(0, 3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.task.stars == 1
                          ? 'Du hast einen\nStern bekommen!'
                          : 'Du hast ${widget.task.stars}\nSterne bekommen!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(
                      height: (b.maxHeight * .41).clamp(215.0, 335.0),
                      width: double.infinity,
                      child: ClipRect(
                        child: OverflowBox(
                          maxWidth: b.maxWidth * 1.19,
                          maxHeight: b.maxWidth * 1.19,
                          alignment: Alignment.topCenter,
                          child: FluffSprite(
                            pose: 'celebrate',
                            size: b.maxWidth * 1.19,
                            animate: widget.controller.data.motion,
                          ),
                        ),
                      ),
                    ),
                    GlossyPanel(
                      radius: 25,
                      child: Row(
                        children: [
                          ArtIcon(widget.task.icon, size: 64),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.task.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '+ ${widget.task.stars} ${widget.task.stars == 1 ? 'Stern' : 'Sterne'}',
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.star_rounded, size: 43, color: gold),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    GlossyButton(
                      'Weiter zur nächsten\nAufgabe',
                      key: const ValueKey('next-task'),
                      color: green,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                    const SizedBox(height: 11),
                    GlossyButton(
                      'Toll gemacht!',
                      color: const Color(0xffffd8bf),
                      icon: Icons.celebration_rounded,
                      small: true,
                      key: const ValueKey('close-celebration'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: MediaQuery.paddingOf(context).top + 2,
            child: IconButton(
              onPressed: () => Navigator.pop(context, false),
              tooltip: 'Sternfeier schließen',
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CelebrationBackground extends StatelessWidget {
  const _CelebrationBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xff472c59),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff080d2c), Color(0xff201436), Color(0xff472c59)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.45, -.12),
              radius: .8,
              colors: [Color(0x88ffbd3b), Color(0x00542136)],
            ),
          ),
        ),
        const CustomPaint(painter: _CelebrationGlow()),
        child,
      ],
    ),
  );
}

class _CelebrationGlow extends CustomPainter {
  const _CelebrationGlow();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (var i = 0; i < 55; i++) {
      final position = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = i % 5 == 0 ? 5.0 : 1.2 + random.nextDouble() * 2;
      final glow = Paint()
        ..color = const Color(0xffffcb64).withValues(alpha: .34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      canvas.drawCircle(position, radius * 2, glow);
      canvas.drawCircle(
        position,
        radius,
        Paint()..color = const Color(0xffffe5a1).withValues(alpha: .65),
      );
    }
  }

  @override
  bool shouldRepaint(_CelebrationGlow oldDelegate) => false;
}

class _Confetti extends CustomPainter {
  const _Confetti(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      gold,
      Color(0xff51d7ff),
      Color(0xffff71ae),
      Color(0xff98ebac),
      Color(0xffb9a0ff),
    ];
    for (var i = 0; i < 36; i++) {
      final x = (i * 173.7) % size.width,
          y = ((t + i * .067) % 1) * size.height;
      final p = Paint()
        ..color = colors[i % colors.length].withValues(alpha: .8);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 4 + i);
      if (i % 3 == 0) {
        final path = Path();
        for (var point = 0; point < 10; point++) {
          final angle = -pi / 2 + point * pi / 5, r = point.isEven ? 7.0 : 3.0;
          final dx = cos(angle) * r, dy = sin(angle) * r;
          if (point == 0) {
            path.moveTo(dx, dy);
          } else {
            path.lineTo(dx, dy);
          }
        }
        path.close();
        canvas.drawPath(path, p);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -6, 6, 12),
            const Radius.circular(1.5),
          ),
          p,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti old) => old.t != t;
}
