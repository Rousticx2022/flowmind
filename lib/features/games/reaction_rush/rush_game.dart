import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Vector2;
import 'package:flutter/material.dart';
import 'components/rush_components.dart';

// World is 10 units wide. Zoom = screenWidth / 10.
const _kWorldW = 10.0;
const _kLaneCount = 4;
const _kLaneW = _kWorldW / _kLaneCount; // 2.5 units per lane

/// Callback when a droplet result is resolved.
typedef DropletCallback = void Function(
    bool correct, int lane, Color color, Offset screenPos);

class ReactionRushGame extends Forge2DGame {
  final DropletCallback onDropletResult;
  final VoidCallback onGameOver;

  ReactionRushGame({
    required this.onDropletResult,
    required this.onGameOver,
  }) : super(gravity: Vector2(0, 18));

  final _rng = Random();
  final _droplets = <String, DropletBody>{};
  bool _active = false;
  int _idCounter = 0;

  // Bucket flash state per lane
  final _flashCorrect = List<bool>.filled(_kLaneCount, true);
  final _flashActive = List<bool>.filled(_kLaneCount, false);
  final _bucketVisuals = <BucketVisual>[];

  double get _worldH => size.y / camera.zoom;
  double get _bucketTopY => _worldH - 3.2;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _setupWorld();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    camera.zoom = newSize.x / _kWorldW;
  }

  void _setupWorld() {
    // Lane dividers
    for (int i = 1; i < _kLaneCount; i++) {
      add(LaneDivider(
        position: Vector2(i * _kLaneW, 0),
        worldHeight: _worldH + 5,
        color: const Color(0xFF1E2B4A),
      ));
    }

    // Bucket visuals
    _bucketVisuals.clear();
    for (int i = 0; i < _kLaneCount; i++) {
      final bv = BucketVisual(
        lane: i,
        laneWidth: _kLaneW,
        position: Vector2(i * _kLaneW + _kLaneW / 2, _bucketTopY),
        accentColor: kDropletColors[i],
      );
      _bucketVisuals.add(bv);
      add(bv);
    }
  }

  // ── Game control ─────────────────────────────────────────────────────────

  void startGame() => _active = true;

  void stopGame() {
    _active = false;
    for (final d in _droplets.values.toList()) {
      d.removeFromParent();
    }
    _droplets.clear();
  }

  void spawnDroplet() {
    if (!_active) return;
    final lane = _rng.nextInt(_kLaneCount);
    final colorIndex = _rng.nextInt(_kLaneCount);
    final x = lane * _kLaneW + _kLaneW / 2;
    final id = 'drop_${_idCounter++}';

    final droplet = DropletBody(
      id: id,
      lane: lane,
      colorIndex: colorIndex,
      position: Vector2(x, 0.3),
    );
    _droplets[id] = droplet;
    add(droplet);
  }

  void tapLane(int tappedLane) {
    if (!_active) return;

    // Find the lowest droplet in this lane
    DropletBody? target;
    double lowestY = -1;

    for (final d in _droplets.values) {
      if (d.lane == tappedLane) {
        final y = d.body.position.y;
        if (y > lowestY) {
          lowestY = y;
          target = d;
        }
      }
    }

    if (target == null) {
      // Empty lane tap - penalty
      _flashLane(tappedLane, false);
      final laneCenter = Offset(
        (tappedLane * _kLaneW + _kLaneW / 2) * camera.zoom,
        _bucketTopY * camera.zoom,
      );
      onDropletResult(false, tappedLane, Colors.grey, laneCenter);
      return;
    }

    final correct = target.colorIndex == tappedLane;
    final color = kDropletColors[target.colorIndex];
    final worldPos = target.body.position;
    final screenPos = Offset(worldPos.x * camera.zoom, worldPos.y * camera.zoom);

    _spawnPhysicsSplash(worldPos, color, correct);
    _flashLane(tappedLane, correct);

    _droplets.remove(target.id);
    target.removeFromParent();

    onDropletResult(correct, tappedLane, color, screenPos);
  }

  // ── Update loop ───────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    final missLine = _worldH + 0.5;

    for (final entry in _droplets.entries.toList()) {
      final d = entry.value;
      if (!d.isLoaded) continue;
      final y = d.body.position.y;

      // Clamp horizontal drift to lane
      final laneCenter = d.lane * _kLaneW + _kLaneW / 2;
      final vel = d.body.linearVelocity;
      if ((d.body.position.x - laneCenter).abs() > _kLaneW * 0.4) {
        d.body.linearVelocity = Vector2(vel.x * -0.5, vel.y);
      }

      // Miss detection
      if (y > missLine) {
        final worldPos = d.body.position;
        final screenPos =
            Offset(worldPos.x * camera.zoom, worldPos.y * camera.zoom);
        _droplets.remove(entry.key);
        d.removeFromParent();
        onDropletResult(false, d.lane, kDropletColors[d.colorIndex], screenPos);
      }
    }
  }

  // ── Effects ──────────────────────────────────────────────────────────────

  void _spawnPhysicsSplash(Vector2 worldPos, Color color, bool correct) {
    add(ParticleSystemComponent(
      position: worldPos.clone(),
      particle: Particle.generate(
        count: correct ? 24 : 12,
        lifespan: 0.65,
        generator: (i) {
          final angle = _rng.nextDouble() * 2 * pi;
          final speed = (_rng.nextDouble() * 3.5 + 1.0);
          return AcceleratedParticle(
            acceleration: Vector2(0, 10),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed - 5),
            child: CircleParticle(
              radius: _rng.nextDouble() * 0.12 + 0.06,
              paint: Paint()
                ..color = correct
                    ? color.withOpacity(0.9)
                    : const Color(0xFFFF4D4D).withOpacity(0.8),
            ),
          );
        },
      ),
    ));

    // Shockwave ring (world units)
    add(ParticleSystemComponent(
      position: worldPos.clone(),
      particle: ComputedParticle(
        lifespan: 0.3,
        renderer: (canvas, p) {
          final t = p.progress;
          canvas.drawCircle(
            Offset.zero,
            t * 1.2,
            Paint()
              ..color = color.withOpacity((1 - t) * 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = (1 - t) * 0.12,
          );
        },
      ),
    ));
  }

  void _flashLane(int lane, bool correct) {
    _flashActive[lane] = true;
    _flashCorrect[lane] = correct;
    _rebuildBucketVisual(lane);

    Future.delayed(const Duration(milliseconds: 260), () {
      _flashActive[lane] = false;
      _rebuildBucketVisual(lane);
    });
  }

  void _rebuildBucketVisual(int lane) {
    if (lane >= _bucketVisuals.length) return;
    final old = _bucketVisuals[lane];
    old.removeFromParent();

    final bv = BucketVisual(
      lane: lane,
      laneWidth: _kLaneW,
      position: Vector2(lane * _kLaneW + _kLaneW / 2, _bucketTopY),
      accentColor: kDropletColors[lane],
      isFlashing: _flashActive[lane],
      flashCorrect: _flashCorrect[lane],
    );
    _bucketVisuals[lane] = bv;
    add(bv);
  }
}
