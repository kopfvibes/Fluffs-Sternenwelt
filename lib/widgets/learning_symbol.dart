import 'package:flutter/material.dart';
import 'common.dart';

class LearningSymbol extends StatelessWidget {
  const LearningSymbol(this.symbol, {super.key, required this.size});
  final String symbol;
  final double size;
  @override
  Widget build(BuildContext context) {
    const circles = {'🔵': blue, '🟡': gold, '🟣': Color(0xff9a65d6), '🟢': green};
    const artwork = {'💙': 'heart', '🧸': 'teddy', '📘': 'book', '🌙': 'moon',
      '🧥': 'shirt', '🧩': 'help', '🤝': 'family'};
    const faces = {'😢': 'sad', '😠': 'angry', '🥱': 'tired', '😊': 'proud',
      '😟': 'unsure', '😄': 'proud'};
    final circle = circles[symbol];
    if (circle != null) {
      return Container(width: size, height: size,
        decoration: BoxDecoration(color: circle, shape: BoxShape.circle));
    }
    final art = artwork[symbol];
    if (art != null) return ArtIcon(art, size: size);
    final face = faces[symbol];
    if (face != null) return FluffSprite(pose: face, size: size, animate: false);
    final icon = switch (symbol) {
      '⭐' || '★' => Icons.star_rounded,
      '●' => Icons.circle,
      '▲' => Icons.change_history_rounded,
      '■' => Icons.square,
      '🌸' => Icons.local_florist_rounded,
      '🍀' => Icons.park_rounded,
      '☀️' => Icons.wb_sunny_rounded,
      '🌈' => Icons.looks_rounded,
      '💧' => Icons.water_drop_rounded,
      '✋' => Icons.back_hand_rounded,
      '🚦' => Icons.traffic_rounded,
      '🌬️' => Icons.air_rounded,
      _ => null,
    };
    if (icon == null) {
      return Text(symbol,
        style: TextStyle(fontSize: size, color: blue, fontWeight: FontWeight.w900));
    }
    final color = switch (symbol) {
      '⭐' || '☀️' => gold,
      '🌸' => const Color(0xffef5d8a),
      '🍀' => green,
      _ => blue,
    };
    return Icon(icon, size: size, color: color);
  }
}
