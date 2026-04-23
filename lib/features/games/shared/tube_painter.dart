import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/tube.dart';

class TubePainter extends CustomPainter {
  final List<Color> segments;
  final bool isSelected;
  final double wavePhase; // 0 → 2π, drives wave animation
  final double pourProgress; // 0.0 → 1.0 for live pour animation (optional)

  static const _wallT = 5.0;
  static const _bottomR = 20.0;

  TubePainter({
    required this.segments,
    this.isSelected = false,
    this.wavePhase = 0.0,
    this.pourProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final iW = w - _wallT * 2; // inner width
    final iH = h - _wallT; // inner height (open top)
    final slotH = iH / kTubeCapacity;

    // ── 1. Clip & fill tube interior (dark well) ──────────────────────
    final interiorPath = _interiorPath(w, h);
    canvas.save();
    canvas.clipPath(interiorPath);

    final bgPaint = Paint()..color = const Color(0xFF0A0F20);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── 2. Draw liquid segments bottom → top ─────────────────────────
    for (int i = 0; i < segments.length; i++) {
      final color = segments[i];
      final isTop = (i == segments.length - 1);

      final top = h - _wallT - (i + 1) * slotH;
      final bottom = h - _wallT - i * slotH;

      final fillPaint = Paint()..color = color;

      if (isTop) {
        // Waved top surface
        final wavePath = Path();
        wavePath.moveTo(_wallT, bottom);
        wavePath.lineTo(_wallT, top + slotH * 0.2);

        const steps = 24;
        const amp = 3.5;
        for (int s = 0; s <= steps; s++) {
          final x = _wallT + iW * s / steps;
          final y = top + sin(wavePhase + s * pi * 2 / steps) * amp;
          wavePath.lineTo(x, y);
        }

        wavePath.lineTo(_wallT + iW, bottom);
        wavePath.close();
        canvas.drawPath(wavePath, fillPaint);
      } else {
        canvas.drawRect(
          Rect.fromLTRB(_wallT, top, w - _wallT, bottom),
          fillPaint,
        );
      }

      // Glossy sheen over each segment
      final sheenRect = Rect.fromLTRB(_wallT, top, w - _wallT, bottom);
      final sheenPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.04),
            Colors.transparent,
          ],
          stops: const [0, 0.3, 1.0],
        ).createShader(sheenRect);
      canvas.drawRect(sheenRect, sheenPaint);
    }

    // ── 3. Bottom reflection gradient ─────────────────────────────────
    if (segments.isNotEmpty) {
      final reflectPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.8, w, h * 0.2));
      canvas.drawRect(Rect.fromLTWH(0, h * 0.8, w, h * 0.2), reflectPaint);
    }

    canvas.restore();

    // ── 4. Draw glass tube wall ────────────────────────────────────────
    _drawGlass(canvas, w, h);
  }

  Path _interiorPath(double w, double h) {
    final ir = _bottomR - _wallT; // inner corner radius
    final path = Path();
    path.moveTo(_wallT, 0);
    path.lineTo(_wallT, h - _wallT - ir);
    path.arcToPoint(
      Offset(_wallT + ir, h - _wallT),
      radius: Radius.circular(ir),
      clockwise: true,
    );
    path.lineTo(w - _wallT - ir, h - _wallT);
    path.arcToPoint(
      Offset(w - _wallT, h - _wallT - ir),
      radius: Radius.circular(ir),
      clockwise: true,
    );
    path.lineTo(w - _wallT, 0);
    path.close();
    return path;
  }

  void _drawGlass(Canvas canvas, double w, double h) {
    final accent = isSelected ? const Color(0xFF00D4FF) : const Color(0xFF2A3A6A);

    // Outer outline path (U shape, open at top)
    final outlinePath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - _bottomR)
      ..arcToPoint(
        Offset(_bottomR, h),
        radius: Radius.circular(_bottomR),
        clockwise: true,
      )
      ..lineTo(w - _bottomR, h)
      ..arcToPoint(
        Offset(w, h - _bottomR),
        radius: Radius.circular(_bottomR),
        clockwise: true,
      )
      ..lineTo(w, 0);

    // Outer glow when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = accent.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _wallT;
      canvas.drawPath(outlinePath, glowPaint);
    }

    // Glass body fill (the tube walls)
    final glassColor = isSelected
        ? accent.withOpacity(0.18)
        : const Color(0xFF1A2445).withOpacity(0.9);

    final innerClip = _interiorPath(w, h);
    final glassPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, w, h)),
      innerClip,
    );
    // Intersect with outer outline to keep U-shape
    final outerFill = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - _bottomR)
      ..arcToPoint(Offset(_bottomR, h), radius: Radius.circular(_bottomR), clockwise: true)
      ..lineTo(w - _bottomR, h)
      ..arcToPoint(Offset(w, h - _bottomR), radius: Radius.circular(_bottomR), clockwise: true)
      ..lineTo(w, 0)
      ..close();

    final wallPath = Path.combine(PathOperation.intersect, glassPath, outerFill);
    canvas.drawPath(wallPath, Paint()..color = glassColor);

    // Border stroke
    final borderPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(outlinePath, borderPaint);

    // Left-side specular highlight
    canvas.drawLine(
      Offset(_wallT * 0.6, 16),
      Offset(_wallT * 0.6, h * 0.65),
      Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.35 : 0.12)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(TubePainter old) =>
      old.segments != segments ||
      old.isSelected != isSelected ||
      old.wavePhase != wavePhase ||
      old.pourProgress != pourProgress;
}
