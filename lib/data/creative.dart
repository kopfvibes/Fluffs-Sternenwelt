class DrawPoint {
  const DrawPoint(this.x, this.y);
  final double x, y;
  List<double> toJson() => [x, y];
  factory DrawPoint.fromJson(List<dynamic> j) =>
      DrawPoint((j[0] as num).toDouble(), (j[1] as num).toDouble());
}

class DrawStroke {
  DrawStroke({required this.color, required this.width, List<DrawPoint>? points})
      : points = points ?? [];
  final int color;
  final double width;
  final List<DrawPoint> points;
  Map<String, dynamic> toJson() => {
    'color': color, 'width': width,
    'points': points.map((p) => p.toJson()).toList(),
  };
  factory DrawStroke.fromJson(Map<String, dynamic> j) => DrawStroke(
    color: j['color'], width: (j['width'] as num).toDouble(),
    points: (j['points'] as List).map((p) => DrawPoint.fromJson(p)).toList(),
  );
}

class SavedDrawing {
  SavedDrawing({required this.id, required this.childId,
    required this.template, required this.createdAt, required this.strokes});
  final String id, childId, createdAt;
  final int template;
  final List<DrawStroke> strokes;
  Map<String, dynamic> toJson() => {
    'id': id, 'childId': childId, 'template': template,
    'createdAt': createdAt, 'strokes': strokes.map((s) => s.toJson()).toList(),
  };
  factory SavedDrawing.fromJson(Map<String, dynamic> j) => SavedDrawing(
    id: j['id'], childId: j['childId'], template: j['template'],
    createdAt: j['createdAt'], strokes: (j['strokes'] as List)
      .map((s) => DrawStroke.fromJson(Map<String, dynamic>.from(s))).toList(),
  );
}

const coloringTitles = [
  'Fluff baut einen Turm', 'Fluffs Blumengarten', 'Fluff und die Sterne',
  'Fluffs Lesezeit', 'Fluff hilft einem Freund', 'Gute Nacht, Fluff',
  'Formen entdecken', 'Meine Zählsterne', 'Der Weg zu Fluff',
  'Muster weiterzeichnen', 'Mein Gefühl heute', 'Mein eigenes Sternenglas',
];
String coloringAsset(int page) =>
    'assets/coloring/page_${page.toString().padLeft(2, '0')}.png';
