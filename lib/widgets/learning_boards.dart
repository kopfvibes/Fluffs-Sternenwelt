import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/discovery.dart';
import 'common.dart';
import 'learning_symbol.dart';

class CountingBoard extends StatelessWidget {
  const CountingBoard({super.key, required this.count, required this.progress,
    required this.onTouch, required this.enabled});
  final int count;
  final ExplorationProgress progress;
  final ValueChanged<int> onTouch;
  final bool enabled;
  @override
  Widget build(BuildContext context) => GlossyPanel(child: Column(children: [
    Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 14, children: [
      for (var i = 0; i < count; i++)
        Semantics(label: progress.visited.contains(i)
          ? 'Stern ${i + 1}, gezählt als ${progress.numberAt(i)}'
          : 'Stern ${i + 1}, noch nicht gezählt', button: true,
          child: InkWell(key: ValueKey('count-star-$i'),
            onTap: enabled ? () => onTouch(i) : null,
            borderRadius: BorderRadius.circular(18),
            child: Container(width: 68, height: 82,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                color: progress.visited.contains(i) ? const Color(0xffd1f8de)
                  : const Color(0xfffff1c4)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.star_rounded, color: gold, size: 45),
                Text(progress.visited.contains(i) ? '${progress.numberAt(i)}' : '•',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ])))),
    ]),
    const SizedBox(height: 12),
    Text('${progress.visited.length} von $count Sternen angetippt',
      textAlign: TextAlign.center),
  ]));
}

class ShapeBoard extends StatelessWidget {
  const ShapeBoard({super.key, required this.shape, required this.progress,
    required this.onTouch, required this.enabled});
  final String shape;
  final ExplorationProgress progress;
  final ValueChanged<int> onTouch;
  final bool enabled;
  @override
  Widget build(BuildContext context) => GlossyPanel(child: Center(child:
    SizedBox(width: 264, height: 264, child: LayoutBuilder(builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight);
      final points = shapePoints(shape, size);
      return Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _ShapePainter(shape))),
        for (var i = 0; i < points.length; i++)
          Positioned(left: points[i].dx - 25, top: points[i].dy - 25,
            child: Semantics(button: true, label: shape == 'circle' ? 'Runde Linie'
              : shape == 'star' ? 'Äußere Spitze ${i + 1}' : 'Ecke ${i + 1}',
              child: InkWell(key: ValueKey('shape-point-$i'),
                onTap: enabled ? () => onTouch(i) : null,
                borderRadius: BorderRadius.circular(25),
                child: Container(width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: progress.visited.contains(i) ? green : gold,
                    border: Border.all(color: Colors.white, width: 3)),
                  child: Center(child: progress.visited.contains(i)
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : const Icon(Icons.touch_app_rounded, color: ink, size: 25)))))),
      ]);
    }))));
}

List<Offset> shapePoints(String shape, double size) {
  final center = Offset(size / 2, size / 2);
  final r = size * .34;
  if (shape == 'circle') return [center + Offset(0, -r)];
  if (shape == 'square') {
    final d = r * .86;
    return [center + Offset(-d,-d), center + Offset(d,-d),
      center + Offset(d,d), center + Offset(-d,d)];
  }
  final n = shape == 'triangle' ? 3 : 5;
  return List.generate(n, (i) => center + Offset(
    r * math.cos(-math.pi / 2 + i * 2 * math.pi / n),
    r * math.sin(-math.pi / 2 + i * 2 * math.pi / n)));
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape);
  final String shape;
  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final center = Offset(s / 2, s / 2);
    final paint = Paint()..color = blue..strokeWidth = 7..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    if (shape == 'circle') { canvas.drawCircle(center, s * .34, paint); return; }
    final points = shapePoints(shape, s);
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i <= points.length; i++) {
      if (shape == 'star') {
        final angle = -math.pi / 2 + (i - .5) * 2 * math.pi / 5;
        path.lineTo(center.dx + s * .15 * math.cos(angle),
          center.dy + s * .15 * math.sin(angle));
      }
      final p = points[i % points.length];
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xffe1f2ff));
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_ShapePainter oldDelegate) => oldDelegate.shape != shape;
}

class PatternBoard extends StatelessWidget {
  const PatternBoard({super.key, required this.question, required this.progress,
    required this.onTouch, required this.enabled, required this.showGroups});
  final LearningQuestion question;
  final ExplorationProgress progress;
  final ValueChanged<int> onTouch;
  final bool enabled, showGroups;
  @override
  Widget build(BuildContext context) {
    final symbols = question.symbols;
    final unit = question.unit.length;
    final groups = <Widget>[];
    for (var start = 0; start < symbols.length; start += unit) {
      groups.add(Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          color: start == 0 || showGroups ? const Color(0xfffff1c4) : Colors.white,
          border: Border.all(color: start == 0 || showGroups ? gold : Colors.transparent,
            width: 2)),
        child: Wrap(spacing: 5, children: [
          for (var i = start; i < math.min(start + unit, symbols.length); i++)
            i < unit ? Semantics(button: true, label: '${symbolNames[symbols[i]]}, '
              'Platz ${i + 1} in der Gruppe',
              child: InkWell(key: ValueKey('pattern-item-$i'),
                onTap: enabled ? () => onTouch(i) : null,
                child: SizedBox(width: 48, height: 68,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    LearningSymbol(symbols[i], size: 38),
                    Icon(progress.visited.contains(i) ? Icons.check_rounded
                      : Icons.touch_app_rounded, size: 20, color: blue),
                  ]))))
            : Padding(padding: const EdgeInsets.all(5),
                child: LearningSymbol(symbols[i], size: 38)),
          if (start + unit >= symbols.length) const Padding(
            padding: EdgeInsets.all(5), child: Text('?', style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: blue))),
        ])));
    }
    return GlossyPanel(child: Wrap(alignment: WrapAlignment.center,
      spacing: 8, runSpacing: 12, children: groups));
  }
}
