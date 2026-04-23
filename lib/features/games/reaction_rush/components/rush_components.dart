import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flutter/material.dart';
import '../rush_game.dart';

const List<Color> kDropletColors = [
  Color(0xFFFF4D4D), // RED
  Color(0xFF4D9FFF), // BLUE
  Color(0xFF4DFF91), // GREEN
  Color(0xFFFFD84D), // YELLOW
];

const List<String> kDropletLabels = ['R', 'B', 'G', 'Y'];

class DropletBody extends BodyComponent<ReactionRushGame> {
  final String id;
  final int lane;
  final int colorIndex;
  final Vector2 _startPos;

  static const radius = 0.55;

  DropletBody({
    required this.id,
    required this.lane,
    required this.colorIndex,
    required Vector2 position,
  }) : _startPos = position.clone();

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _startPos,
      type: BodyType.dynamic,
      linearDamping: 0.15,
      bullet: true,
    );
    final body = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;
    body.createFixtureFromShape(shape, density: 0.8, restitution: 0.0);

    return body;
  }

  @override
  void render(Canvas canvas) {
    final color = kDropletColors[colorIndex];
    final label = kDropletLabels[colorIndex];

    // Outer glow
    canvas.drawCircle(
      Offset.zero,
      radius * 1.5,
      Paint()
        ..color = color.withOpacity(0.2)
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 0.4),
    );

    // Main drop body
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color);

    // Shine
    canvas.drawCircle(
      const Offset(-0.15, -0.15),
      radius * 0.38,
      Paint()..color = Colors.white.withOpacity(0.35),
    );

    // Letter
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(-tp.width / 2, -tp.height / 2),
    );
  }
}

/// Static boundary at the bottom to detect misses
class GroundBoundary extends BodyComponent<ReactionRushGame> {
  final double worldWidth;
  final double yPos;

  GroundBoundary({required this.worldWidth, required this.yPos});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: Vector2(worldWidth / 2, yPos),
      type: BodyType.static,
    );
    final body = world.createBody(bodyDef);
    final shape = PolygonShape()
      ..setAsBox(worldWidth / 2, 0.1, Vector2.zero(), 0);
    body.createFixtureFromShape(shape);
    return body;
  }

  @override
  void render(Canvas canvas) {}
  @override
  bool get debugMode => false;
}

/// Visual lane dividers (not physics bodies)
class LaneDivider extends PositionComponent {
  final double worldHeight;
  final Color color;

  LaneDivider({
    required Vector2 position,
    required this.worldHeight,
    required this.color,
  }) : super(position: position);

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      Offset.zero,
      Offset(0, worldHeight),
      Paint()
        ..color = color
        ..strokeWidth = 0.03,
    );
  }
}

/// Visual bucket at the bottom of each lane
class BucketVisual extends PositionComponent {
  final int lane;
  final double laneWidth;
  final bool isFlashing;
  final bool flashCorrect;
  final Color accentColor;

  BucketVisual({
    required this.lane,
    required this.laneWidth,
    required Vector2 position,
    required this.accentColor,
    this.isFlashing = false,
    this.flashCorrect = true,
  }) : super(position: position, size: Vector2(laneWidth, 1.8));

  @override
  void render(Canvas canvas) {
    final color = isFlashing
        ? (flashCorrect ? const Color(0xFF4DFFC3) : const Color(0xFFFF4D4D))
        : accentColor;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-laneWidth / 2 + 0.15, 0, laneWidth - 0.3, 1.6),
      const Radius.circular(0.2),
    );

    // Bucket fill
    canvas.drawRRect(
      rrect,
      Paint()..color = color.withOpacity(isFlashing ? 0.35 : 0.12),
    );

    // Bucket border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withOpacity(isFlashing ? 1.0 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isFlashing ? 0.08 : 0.05,
    );

    if (isFlashing) {
      // Glow
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3),
      );
    }

    // Icon
    final iconColor = color.withOpacity(isFlashing ? 1.0 : 0.7);
    _drawDropletIcon(canvas, laneWidth / 2, 0.8, iconColor);
  }

  void _drawDropletIcon(Canvas canvas, double cx, double cy, Color color) {
    final path = Path();
    const r = 0.22;
    path.moveTo(cx, cy - r * 1.5);
    path.cubicTo(cx + r, cy - r * 0.3, cx + r, cy + r, cx, cy + r);
    path.cubicTo(cx - r, cy + r, cx - r, cy - r * 0.3, cx, cy - r * 1.5);
    canvas.drawPath(path, Paint()..color = color);
  }
}
