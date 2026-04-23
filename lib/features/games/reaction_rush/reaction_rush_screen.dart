import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../flame/effects_game.dart';
import 'components/rush_components.dart';
import 'reaction_rush_provider.dart';
import 'rush_game.dart';

class ReactionRushScreen extends ConsumerStatefulWidget {
  const ReactionRushScreen({super.key});

  @override
  ConsumerState<ReactionRushScreen> createState() =>
      _ReactionRushScreenState();
}

class _ReactionRushScreenState extends ConsumerState<ReactionRushScreen> {
  late final ReactionRushGame _rushGame;
  late final FlowEffectsGame _effectsGame;
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    _effectsGame = FlowEffectsGame();
    _rushGame = ReactionRushGame(
      onDropletResult: _handleDropletResult,
      onGameOver: _handleGameOver,
    );
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _handleDropletResult(
      bool correct, int lane, Color color, Offset screenPos) {
    if (!mounted) return;
    ref.read(reactionRushProvider.notifier).recordResult(correct);
    _effectsGame.spawnFeedback(screenPos, correct);
    if (correct) {
      _effectsGame.spawnBubbles(screenPos, color, count: 8);
    }

    // Game over from lives
    if (ref.read(reactionRushProvider).phase == RushPhase.gameOver) {
      _endGame();
    }
  }

  void _handleGameOver() => _endGame();

  void _endGame() {
    _spawnTimer?.cancel();
    _rushGame.stopGame();
  }

  void _startGame() {
    ref.read(reactionRushProvider.notifier).startGame();
    _rushGame.startGame();
    _scheduleSpawn(600);
  }

  void _scheduleSpawn(int delayMs) {
    _spawnTimer?.cancel();
    _spawnTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      final state = ref.read(reactionRushProvider);
      if (state.phase != RushPhase.playing) return;
      _rushGame.spawnDroplet();

      // Accelerate as time runs out
      final elapsed = kGameDuration - state.timeLeft;
      final nextDelay = (700 - elapsed * 8).clamp(280, 700).toInt();
      _scheduleSpawn(nextDelay);
    });
  }

  void _restart() {
    _spawnTimer?.cancel();
    _rushGame.stopGame();
    ref.read(reactionRushProvider.notifier).restart();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reactionRushProvider);

    // Start/stop game based on phase transitions
    ref.listen(reactionRushProvider, (prev, next) {
      if (next.phase == RushPhase.gameOver &&
          prev?.phase == RushPhase.playing) {
        _endGame();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── Forge2D Physics Game ────────────────────────────────
          Positioned.fill(
            child: GameWidget(
              game: _rushGame,
              backgroundBuilder: (ctx) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1000), Color(0xFF060810)],
                  ),
                ),
              ),
            ),
          ),

          // ── Flame Effects Overlay ────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget(game: _effectsGame),
            ),
          ),

          // ── Flutter HUD ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  state: state,
                  onBack: () {
                    _endGame();
                    ref.read(reactionRushProvider.notifier).restart();
                    context.go('/');
                  },
                ),
                if (state.phase == RushPhase.playing)
                  _TimerBar(timeLeft: state.timeLeft),
                const Spacer(),
                if (state.phase == RushPhase.idle) _IdleOverlay(onStart: _startGame),
                if (state.phase == RushPhase.gameOver)
                  _GameOverOverlay(state: state, onRestart: _restart),
                // Tap buttons at bottom
                if (state.phase == RushPhase.playing)
                  _BucketButtons(onTapLane: _rushGame.tapLane),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final ReactionRushState state;
  final VoidCallback onBack;

  const _TopBar({required this.state, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _IconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REACTION RUSH',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                if (state.phase == RushPhase.playing)
                  Text('${state.score} pts',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (state.combo >= 2)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Text('×${state.combo}',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(
                5,
                (i) => Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(Icons.water_drop_rounded,
                          color: i < state.lives
                              ? AppColors.cyan
                              : AppColors.textMuted,
                          size: 16),
                    )),
          ),
        ],
      ),
    );
  }
}

// ── Timer Bar ──────────────────────────────────────────────────────────────
class _TimerBar extends StatelessWidget {
  final int timeLeft;

  const _TimerBar({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final ratio = timeLeft / kGameDuration;
    final color = ratio > 0.5
        ? AppColors.mint
        : ratio > 0.25
            ? AppColors.gold
            : AppColors.coral;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.cardBorder.withOpacity(0.4),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${timeLeft}s',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Bucket Tap Buttons ─────────────────────────────────────────────────────
class _BucketButtons extends StatelessWidget {
  final void Function(int) onTapLane;

  const _BucketButtons({required this.onTapLane});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(kDropletColors.length, (i) {
          final color = kDropletColors[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTapLane(i),
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.45), width: 1.5),
                ),
                child: Icon(Icons.water_drop_rounded, color: color, size: 26),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Idle Overlay ───────────────────────────────────────────────────────────
class _IdleOverlay extends StatelessWidget {
  final VoidCallback onStart;

  const _IdleOverlay({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('REACTION RUSH',
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const SizedBox(height: 10),
          const Text(
            'Colored droplets fall with real physics.\nTap the matching bucket to catch them!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text('Wrong color = −1 life  •  Miss = −1 life',
              style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 28),
          // Color key
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final color = kDropletColors[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.5), blurRadius: 12)
                  ],
                ),
                child: Center(
                  child: Text(
                    kDropletLabels[i],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 6))
                ],
              ),
              child: const Text('PLAY',
                  style: TextStyle(
                      color: AppColors.bg,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game Over ──────────────────────────────────────────────────────────────
class _GameOverOverlay extends StatelessWidget {
  final ReactionRushState state;
  final VoidCallback onRestart;

  const _GameOverOverlay({required this.state, required this.onRestart});

  String get _rank {
    if (state.score >= 400) return 'S';
    if (state.score >= 250) return 'A';
    if (state.score >= 150) return 'B';
    if (state.score >= 80) return 'C';
    return 'D';
  }

  Color get _rankColor => switch (_rank) {
        'S' => AppColors.gold,
        'A' => AppColors.mint,
        'B' => AppColors.cyan,
        'C' => AppColors.textSecondary,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _rankColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _rankColor.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor.withOpacity(0.12),
              border: Border.all(color: _rankColor, width: 2.5),
            ),
            child: Center(
              child: Text(_rank,
                  style: TextStyle(
                      color: _rankColor,
                      fontSize: 34,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 14),
          Text('${state.score}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 46,
                  fontWeight: FontWeight.w800)),
          const Text('POINTS',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _StatTile(
                  label: 'Lives Left',
                  value: '${state.lives}/5',
                  color: AppColors.coral),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                  label: 'Time',
                  value: '${kGameDuration - state.timeLeft}s',
                  color: AppColors.cyan),
            ),
          ]),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRestart,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: AppColors.bg, size: 18),
                    SizedBox(width: 6),
                    Text('PLAY AGAIN',
                        style: TextStyle(
                            color: AppColors.bg,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.5)),
                  ]),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Center(
                  child: Text('Back to Menu',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600))),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10)),
        ]),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder)),
          child:
              Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      );
}
