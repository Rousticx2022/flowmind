import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// A fully transparent FlameGame used as a particle overlay on top of
/// every mini-game. Drop it in a Stack with IgnorePointer so it captures
/// no touch events.
class FlowEffectsGame extends FlameGame {
  final _rng = Random();

  @override
  Color backgroundColor() => Colors.transparent;

  // ── Splash ─────────────────────────────────────────────────────────────
  /// Spray liquid droplets outward from [screenPos].
  void spawnSplash(
    Offset screenPos,
    Color color, {
    int count = 22,
    double power = 1.0,
  }) {
    final pos = Vector2(screenPos.dx, screenPos.dy);

    add(ParticleSystemComponent(
      position: pos,
      particle: Particle.generate(
        count: count,
        lifespan: 0.75 * power,
        generator: (i) {
          final angle = _rng.nextDouble() * 2 * pi;
          final speed = (_rng.nextDouble() * 180 + 60) * power;
          final size = _rng.nextDouble() * 4 + 2;
          return AcceleratedParticle(
            acceleration: Vector2(0, 380),
            speed: Vector2(
              cos(angle) * speed,
              sin(angle) * speed - 220 * power,
            ),
            child: CircleParticle(
              radius: size,
              paint: Paint()..color = color.withOpacity(0.85),
            ),
          );
        },
      ),
    ));

    // Shockwave ring
    add(ParticleSystemComponent(
      position: pos,
      particle: ComputedParticle(
        lifespan: 0.35,
        renderer: (canvas, particle) {
          final t = particle.progress;
          final r = t * 35.0;
          canvas.drawCircle(
            Offset.zero,
            r,
            Paint()
              ..color = color.withOpacity((1 - t) * 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = (1 - t) * 3.5,
          );
        },
      ),
    ));
  }

  // ── Pour arc ───────────────────────────────────────────────────────────
  /// Animated arc of liquid droplets from [from] to [to].
  void spawnPourArc(Offset from, Offset to, Color color, {int count = 28}) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;

    add(ParticleSystemComponent(
      position: Vector2(from.dx, from.dy),
      particle: Particle.generate(
        count: count,
        lifespan: 0.55,
        generator: (i) {
          final t = i / count; // 0..1 along the arc
          // Parabolic arc interpolation
          final arcX = dx * t;
          final arcY = dy * t - 60 * sin(pi * t); // upward bulge
          final jitterX = (_rng.nextDouble() - 0.5) * 10;
          final jitterY = (_rng.nextDouble() - 0.5) * 10;
          final size = _rng.nextDouble() * 3.5 + 2.0;

          return MovingParticle(
            from: Vector2.zero(),
            to: Vector2(arcX + jitterX, arcY + jitterY),
            curve: Curves.easeOut,
            child: CircleParticle(
              radius: size,
              paint: Paint()..color = color.withOpacity(0.9),
            ),
          );
        },
      ),
    ));
  }

  // ── Celebration ────────────────────────────────────────────────────────
  /// Multi-burst confetti from multiple positions at the top.
  void spawnCelebration(Size screenSize) {
    const burstCount = 6;
    for (int b = 0; b < burstCount; b++) {
      final delay = b * 0.18;
      Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
        if (!isMounted) return;
        final x = (_rng.nextDouble() * 0.8 + 0.1) * screenSize.width;
        final y = (_rng.nextDouble() * 0.35) * screenSize.height;
        _spawnBurst(Vector2(x, y));
      });
    }
  }

  void _spawnBurst(Vector2 pos) {
    add(ParticleSystemComponent(
      position: pos,
      particle: Particle.generate(
        count: 30,
        lifespan: 1.4,
        generator: (i) {
          final color =
              AppColors.liquids[_rng.nextInt(AppColors.liquids.length)];
          final angle = _rng.nextDouble() * 2 * pi;
          final speed = _rng.nextDouble() * 250 + 80;
          final isRect = _rng.nextBool();
          final size = _rng.nextDouble() * 5 + 3;

          return AcceleratedParticle(
            acceleration: Vector2(0, 320),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed - 300),
            child: isRect
                ? RectangleParticle(
                    size: Vector2(size, size * 1.8),
                    paint: Paint()..color = color.withOpacity(0.9),
                  )
                : CircleParticle(
                    radius: size / 2,
                    paint: Paint()..color = color.withOpacity(0.9),
                  ),
          );
        },
      ),
    ));
  }

  // ── Hit flash ─────────────────────────────────────────────────────────
  /// Quick green or red burst for correct/incorrect feedback.
  void spawnFeedback(Offset screenPos, bool correct) {
    final color = correct ? AppColors.mint : AppColors.coral;
    spawnSplash(screenPos, color, count: correct ? 18 : 12, power: 0.7);
  }

  // ── Glow trail ────────────────────────────────────────────────────────
  /// Subtle rising bubbles from [screenPos] (e.g. jug fill).
  void spawnBubbles(Offset screenPos, Color color, {int count = 12}) {
    final pos = Vector2(screenPos.dx, screenPos.dy);
    add(ParticleSystemComponent(
      position: pos,
      particle: Particle.generate(
        count: count,
        lifespan: 0.9,
        generator: (i) {
          final x = (_rng.nextDouble() - 0.5) * 30;
          final speed = _rng.nextDouble() * 80 + 40;
          final size = _rng.nextDouble() * 4 + 2;
          return AcceleratedParticle(
            acceleration: Vector2(0, -10),
            speed: Vector2(x, -speed),
            child: CircleParticle(
              radius: size,
              paint: Paint()
                ..color = color.withOpacity(0.55)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2,
            ),
          );
        },
      ),
    ));
  }

  bool get isMounted => isLoaded;
}
