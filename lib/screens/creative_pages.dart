import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/controller.dart';
import '../data/creative.dart';
import '../services/fluff_printing.dart';
import '../widgets/common.dart';
import 'parents_screen.dart';

class CreativeStudioPage extends StatelessWidget {
  const CreativeStudioPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Fluffs Malatelier')),
      body: WorldBackground(child: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), children: [
          Row(children: [FluffSprite(pose: 'proud', size: 112,
            animate: controller.data.motion),
            const Expanded(child: Text('Deine Farben.\nDeine Ideen.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)))]),
          GlossyButton('Freies Malen', key: const ValueKey('free-drawing'),
            color: green, onPressed: () => _open(context, 0)),
          const SizedBox(height: 18),
          Text('Fluffs Ausmalbilder', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (var i = 1; i <= coloringTitles.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 10),
              child: GlossyPanel(onTap: () {
                if (controller.proActive) { _open(context, i); } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Deine Eltern können diese Bilder mit Fluff Pro öffnen.')));
                }
              }, child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: Image.asset(coloringAsset(i), width: 48, height: 66,
                    fit: BoxFit.cover)),
                const SizedBox(width: 14),
                Expanded(child: Text(coloringTitles[i - 1], style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800))),
                Icon(controller.proActive ? Icons.brush_rounded : Icons.lock_outline_rounded,
                  color: blue),
              ]))),
          const SizedBox(height: 12),
          Text('Mein Bilderalbum', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (controller.childDrawings.isEmpty)
            const Text('Hier wohnen bald deine eigenen Kunstwerke.')
          else
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, childAspectRatio: .72,
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              children: [for (final drawing in controller.childDrawings)
                InkWell(onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => DrawingPage(controller: controller, saved: drawing,
                    template: drawing.template))),
                  child: Column(children: [Expanded(child: DrawingSurface(
                    template: drawing.template, strokes: drawing.strokes)),
                    const SizedBox(height: 5),
                    Text(drawing.template == 0 ? 'Mein Bild' :
                      coloringTitles[drawing.template - 1], maxLines: 2,
                      overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  ])),
              ]),
        ]))),
    ));
  void _open(BuildContext context, int template) => Navigator.push(context,
    MaterialPageRoute<void>(builder: (_) => DrawingPage(controller: controller,
      template: template)));
}

class DrawingSurface extends StatelessWidget {
  const DrawingSurface({super.key, required this.template, required this.strokes,
    this.onStart, this.onMove});
  final int template;
  final List<DrawStroke> strokes;
  final void Function(Offset, Size)? onStart, onMove;
  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 1 / 1.4142,
    child: LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(behavior: HitTestBehavior.opaque,
        onTapUp: onStart == null ? null : (d) => onStart!(d.localPosition, size),
        onPanStart: onStart == null ? null : (d) => onStart!(d.localPosition, size),
        onPanUpdate: onMove == null ? null : (d) => onMove!(d.localPosition, size),
        child: ClipRect(child: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Colors.white),
          if (template > 0) Image.asset(coloringAsset(template), fit: BoxFit.fill),
          CustomPaint(painter: DrawingPainter(strokes)),
        ])));
    }));
}

class DrawingPainter extends CustomPainter {
  const DrawingPainter(this.strokes);
  final List<DrawStroke> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.multiply);
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final paint = Paint()..color = Color(s.color)
        ..strokeWidth = s.width * size.width..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
      if (s.points.length == 1) {
        canvas.drawCircle(Offset(s.points.first.x * size.width,
          s.points.first.y * size.height), paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill);
      } else {
        final path = Path()..moveTo(s.points.first.x * size.width,
          s.points.first.y * size.height);
        for (final p in s.points.skip(1)) { path.lineTo(p.x * size.width, p.y * size.height); }
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key, required this.controller, required this.template,
    this.saved});
  final AppController controller;
  final int template;
  final SavedDrawing? saved;
  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final boundary = GlobalKey();
  final redo = <DrawStroke>[];
  late final List<DrawStroke> strokes;
  late final String childId;
  String? drawingId;
  Color selected = const Color(0xffef5d8a);
  double width = .015;
  bool dirty = false, saving = false;
  @override
  void initState() {
    super.initState();
    childId = widget.saved?.childId ?? widget.controller.child.id;
    drawingId = widget.saved?.id;
    strokes = widget.saved?.strokes.map((s) => DrawStroke.fromJson(s.toJson())).toList() ?? [];
  }
  DrawPoint point(Offset p, Size s) => DrawPoint(
    (p.dx / s.width).clamp(0, 1).toDouble(), (p.dy / s.height).clamp(0, 1).toDouble());
  void start(Offset p, Size s) {
    if (saving || strokes.length >= 400) return;
    setState(() { redo.clear(); dirty = true;
      strokes.add(DrawStroke(color: selected.toARGB32(), width: width,
        points: [point(p, s)])); });
  }
  void move(Offset p, Size s) {
    if (saving || strokes.isEmpty || strokes.last.points.length >= 3000) return;
    setState(() { strokes.last.points.add(point(p, s)); dirty = true; });
  }
  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.controller.saveDrawing(widget.template, strokes,
        drawingId: drawingId, childId: childId);
      final matches = widget.controller.data.drawings.where((x) => x.childId == childId);
      drawingId ??= matches.last.id;
      if (mounted) {
        setState(() => dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dein Bild ist im Album gespeichert.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is StateError ? e.message.toString() :
            'Dein Bild konnte nicht gespeichert werden. Bitte versuche es noch einmal.')));
      }
    } finally { if (mounted) setState(() => saving = false); }
  }
  Future<bool> confirmLeave() async {
    if (!dirty) return true;
    return await showDialog<bool>(context: context, builder: (d) => AlertDialog(
      title: const Text('Bild noch nicht gespeichert'),
      content: const Text('Möchtest du erst weiter malen oder dieses Bild verlassen?'),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false),
        child: const Text('Weiter malen')), TextButton(
        onPressed: () => Navigator.pop(d, true), child: const Text('Verlassen'))],
    )) ?? false;
  }
  Future<void> print() async {
    final accepted = await showDialog<bool>(context: context,
      builder: (_) => ParentPinDialog(controller: widget.controller));
    if (accepted != true || !mounted) return;
    await act(context, () async {
      final render = boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2.5);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = await FluffPrinting.drawing(data!.buffer.asUint8List());
        widget.controller.externalFilePicker = true;
        try { await FluffPrinting.output(bytes, filename: 'Mein-Fluff-Bild.pdf', share: true); }
        finally { widget.controller.externalFilePicker = false; }
      } finally { image.dispose(); }
    });
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      if (await confirmLeave() && mounted) {
        setState(() => dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(appBar: AppBar(title: const Text('Meine Farben'), actions: [
      IconButton(tooltip: 'Mit Eltern als PDF teilen', icon: const Icon(Icons.print_rounded),
        onPressed: print),
      if (drawingId != null) IconButton(tooltip: 'Bild aus Album löschen',
        icon: const Icon(Icons.delete_outline_rounded), onPressed: () async {
          final yes = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
            title: const Text('Dieses Bild löschen?'),
            actions: [TextButton(onPressed: () => Navigator.pop(d, false),
              child: const Text('Behalten')), TextButton(onPressed: () => Navigator.pop(d, true),
              child: const Text('Löschen'))]));
          if (yes == true) {
            await widget.controller.deleteDrawing(drawingId!);
            if (context.mounted) { setState(() => dirty = false); Navigator.pop(context); }
          }
        }),
    ]), body: SafeArea(child: LayoutBuilder(builder: (context, box) =>
      Column(children: [
        Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(12),
          child: RepaintBoundary(key: boundary, child: DrawingSurface(
            key: const ValueKey('drawing-canvas'), template: widget.template,
            strokes: strokes, onStart: start, onMove: move))))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(spacing: 7, runSpacing: 6, alignment: WrapAlignment.center,
            children: [for (final color in const [Color(0xffef5d8a), Color(0xffffb732),
              Color(0xff40bf68), Color(0xff278df4), Color(0xff9a65d6), Color(0xffed574d),
              Color(0xff795548), Color(0xff202020), Colors.white])
              Semantics(label: 'Malfarbe auswählen', selected: selected == color,
                child: InkWell(onTap: () => setState(() => selected = color),
                  child: Container(width: 34, height: 34, decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    border: Border.all(width: selected == color ? 3 : 1,
                      color: selected == color ? blue : Colors.black26))))),
            ])),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(tooltip: 'Rückgängig', icon: const Icon(Icons.undo_rounded),
            onPressed: strokes.isEmpty ? null : () => setState(() {
              redo.add(strokes.removeLast()); dirty = true;
            })),
          IconButton(tooltip: 'Wiederholen', icon: const Icon(Icons.redo_rounded),
            onPressed: redo.isEmpty ? null : () => setState(() {
              strokes.add(redo.removeLast()); dirty = true;
            })),
          const Text('Pinsel'),
          Expanded(child: Slider(value: width, min: .005, max: .04,
            onChanged: (v) => setState(() => width = v))),
        ]),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GlossyButton(saving ? 'Wird gespeichert …' : 'Im Album speichern',
            key: const ValueKey('save-drawing'), color: green,
            onPressed: saving ? null : save)),
      ]))),
    ));
}
