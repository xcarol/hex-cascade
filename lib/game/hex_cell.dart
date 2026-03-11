import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class HexCell extends PositionComponent with TapCallbacks {
  final int row;
  final int col;
  TileColor color;

  static const double hexSize = 36.0; // circumradius

  double _scale = 1.0;
  bool _animating = false;
  double _animTimer = 0;

  HexCell({
    required this.row,
    required this.col,
    required this.color,
    required Vector2 pos,
  }) : super(
         position: pos,
         size: Vector2.all(hexSize * 2),
         anchor: Anchor.center,
       );

  @override
  void update(double dt) {
    super.update(dt);
    if (_animating) {
      _animTimer += dt;
      if (_animTimer < 0.1) {
        _scale = 1.0 - _animTimer * 3;
      } else if (_animTimer < 0.2) {
        _scale = 0.7 + (_animTimer - 0.1) * 3;
      } else {
        _scale = 1.0;
        _animating = false;
        _animTimer = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.black;
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.x / 2, size.y / 2);
    final path = _hexPath(center, HexCell.hexSize * _scale * 0.9);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, highlightPaint);
  }

  Path _hexPath(Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Vector2 positionFor(int row, int col, {Vector2? offset}) {
    const w = hexSize * 1.73205080757; // sqrt(3)
    const h = hexSize * 2;
    final x = col * w + (row % 2 == 1 ? w / 2 : 0);
    final y = row * h * 0.75;
    final base = offset ?? Vector2.zero();
    return Vector2(base.x + x, base.y + y);
  }
}
