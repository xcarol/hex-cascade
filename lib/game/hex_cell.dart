import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'hex_game.dart';

enum PlacementMode { none, normalOccupied, special, negative }

class HexCell extends PositionComponent with TapCallbacks {
  final void Function(int row, int col)? onTapped;

  final int row;
  final int col;
  int? value;
  TileColor? color;
  PlacementMode placementMode = PlacementMode.normalOccupied;

  static const double hexSize = 36.0;
  static const Color _emptyColor = Color(0xFF1A2A3A);
  static const Color _filledColor = Color(0xFF4A7A9B);

  double _scale = 1.0;
  bool _animating = false;
  double _animTimer = 0;

  HexCell({
    required this.row,
    required this.col,
    this.value,
    this.color,
    required Vector2 pos,
    this.onTapped,
  }) : super(
         position: pos,
         size: Vector2.all(hexSize * 2),
         anchor: Anchor.center,
       );

  @override
  bool containsLocalPoint(Vector2 point) {
    final center = size / 2;
    final path = _hexPath(center.toOffset(), hexSize);
    return path.contains(point.toOffset());
  }

  bool get isEmpty => value == null && color == null;

  @override
  void onTapDown(TapDownEvent event) {
    switch (placementMode) {
      case PlacementMode.none:
        break;
      case PlacementMode.normalOccupied:
        onTapped?.call(row, col);
      case PlacementMode.special:
        onTapped?.call(row, col);
      case PlacementMode.negative:
        if (!isEmpty) onTapped?.call(row, col);
    }
  }

  void playAnimation() {
    _animating = true;
    _animTimer = 0;
  }

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
    final center = Offset(size.x / 2, size.y / 2);
    final r = hexSize * _scale * 0.9;

    Color currentFilledColor = _filledColor;
    Color textColor = Colors.white;

    if (!isEmpty && value != null) {
      int threshold = 10;
      try {
        threshold = (findGame() as HexCascadeGame).state.explosionThreshold;
      } catch (_) {}

      final ratio = (value! / threshold).clamp(0.0, 1.0);
      currentFilledColor = Color.lerp(Colors.white, const Color(0xFF1565C0), ratio) ?? _filledColor;
      
      if (ratio < 0.4) {
        textColor = const Color(0xFF0D1B2A); // Dark text for very light background
      }
    }

    final fillPaint = Paint()..color = isEmpty ? _emptyColor : currentFilledColor;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = _hexPath(center, r);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    if (!isEmpty) {
      final text = value?.toString() ?? '';
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Path _hexPath(Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  static Vector2 positionFor(int row, int col, {Vector2? offset}) {
    const w = hexSize * 1.73205080757;
    const h = hexSize * 2;
    final x = col * w + (row % 2 == 1 ? w / 2 : 0);
    final y = row * h * 0.75;
    final base = offset ?? Vector2.zero();
    return Vector2(base.x + x, base.y + y);
  }
}
