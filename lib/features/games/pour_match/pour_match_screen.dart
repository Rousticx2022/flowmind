import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../flame/effects_game.dart';
import '../../../models/level_config.dart';
import '../shared/tube_widget.dart';
import 'pour_match_provider.dart';

class PourMatchScreen extends ConsumerStatefulWidget {
  final int level;
  const PourMatchScreen({super.key, this.level = 1});

  @override
  ConsumerState<PourMatchScreen> createState() => _PourMatchScreenState();
}

class _PourMatchScreenState extends ConsumerState<PourMatchScreen> {
  late final FlowEffectsGame _effectsGame;
  int _prevMoves = 0;
  bool _wasComplete = false;

  int get _levelIdx =>
      (widget.level - 1).clamp(0, pourMatchLevels.length - 1);

  @override
  void initState() {
    super.initState();
    _effectsGame = FlowEffectsGame();
  }

  void _onPour(Offset fromOffset, Offset toOffset, Color color) {
    _effectsGame.spawnPourArc(fromOffset, toOffset, color);
    _effectsGame.spawnBubbles(toOffset, color, count: 8);
  }

  @override
  Widget build(BuildContext context) {
    final levelData = pourMatchLevels[_levelIdx];
    final state = ref.watch(pourMatchProvider(_levelIdx));
    final notifier = ref.read(pourMatchProvider(_levelIdx).notifier);

    // Detect pour (moves increased)
    if (state.moves > _prevMoves && !state.isComplete) {
      _prevMoves = state.moves;
      // Splash in center of screen as approximation
      final size = MediaQuery.of(context).size;
      final center = Offset(size.width / 2, size.height / 2);
      if (state.tubes.isNotEmpty) {
        final color = state.tubes
            .where((t) => !t.isEmpty)
            .fold<Color>(AppColors.cyan, (_, t) => t.topColor ?? AppColors.cyan);
        _effectsGame.spawnSplash(center, color, count: 14, power: 0.8);
      }
    }

    // Win celebration
    if (state.isComplete && !_wasComplete) {
      _wasComplete = true;
      final size = MediaQuery.of(context).size;
      _effectsGame.spawnCelebration(size);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _showWinDialog(context, state.moves, widget.level);
      });
    }

    if (!state.isComplete) _wasComplete = false;
    _prevMoves = state.moves;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0E1F), Color(0xFF060810)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    levelData: levelData,
                    moves: state.moves,
                    canUndo: state.history.isNotEmpty,
                    onUndo: notifier.undo,
                    onReset: () => notifier.reset(_levelIdx),
                  ),
                  const SizedBox(height: 12),

                  // ── Hint text ─────────────────────────────────────
                  Text(
                    state.selectedIndex != null
                        ? 'Now tap a destination tube'
                        : 'Tap a tube to select',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(),

                  // ── Tube grid ─────────────────────────────────────
                  _TubeGrid(state: state, onTap: notifier.tap),

                  const Spacer(),

                  // ── Move counter ──────────────────────────────────
                  _MoveCounter(moves: state.moves),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Flame Effects Overlay ──────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget(game: _effectsGame),
            ),
          ),
        ],
      ),
    );
  }

  void _showWinDialog(BuildContext context, int moves, int currentLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDialog(moves: moves, currentLevel: currentLevel),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final PourMatchLevel levelData;
  final int moves;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onReset;

  const _TopBar({
    required this.levelData,
    required this.moves,
    required this.canUndo,
    required this.onUndo,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back
          _IconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.go('/'),
          ),
          const SizedBox(width: 12),

          // Level info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEVEL ${levelData.number}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  levelData.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _diffColor(levelData.difficulty).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _diffColor(levelData.difficulty).withOpacity(0.4),
              ),
            ),
            child: Text(
              levelData.difficulty,
              style: TextStyle(
                color: _diffColor(levelData.difficulty),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Undo
          _IconBtn(
            icon: Icons.undo_rounded,
            onTap: canUndo ? onUndo : null,
            color: canUndo ? AppColors.textPrimary : AppColors.textMuted,
          ),

          // Reset
          _IconBtn(icon: Icons.refresh_rounded, onTap: onReset),
        ],
      ),
    );
  }

  Color _diffColor(String d) => switch (d) {
        'Easy' => AppColors.mint,
        'Medium' => AppColors.gold,
        _ => AppColors.coral,
      };
}

// ── Tube Grid ──────────────────────────────────────────────────────────────
class _TubeGrid extends StatelessWidget {
  final PourMatchState state;
  final void Function(int) onTap;

  const _TubeGrid({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tubes = state.tubes;
    final count = tubes.length;

    // Responsive: max 5 per row
    const maxPerRow = 5;
    const tubeW = 56.0;
    const tubeH = 200.0;
    const gap = 14.0;

    final rows = <List<int>>[];
    for (int i = 0; i < count; i += maxPerRow) {
      rows.add(
        List.generate(
          (count - i) < maxPerRow ? count - i : maxPerRow,
          (j) => i + j,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((idx) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: gap / 2),
                child: TubeWidget(
                  tube: tubes[idx],
                  isSelected: state.selectedIndex == idx,
                  onTap: () => onTap(idx),
                  width: tubeW,
                  height: tubeH,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ── Move Counter ───────────────────────────────────────────────────────────
class _MoveCounter extends StatelessWidget {
  final int moves;
  const _MoveCounter({required this.moves});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.swap_horiz_rounded, color: AppColors.cyan, size: 18),
        const SizedBox(width: 6),
        Text(
          '$moves ${moves == 1 ? 'move' : 'moves'}',
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── Win Dialog ─────────────────────────────────────────────────────────────
class _WinDialog extends StatelessWidget {
  final int moves;
  final int currentLevel;
  const _WinDialog({required this.moves, required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final hasNext = currentLevel < pourMatchLevels.length;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cyan.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text(
              'SORTED!',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed in $moves ${moves == 1 ? 'move' : 'moves'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _DialogBtn(
                    label: 'Menu',
                    color: AppColors.cardBorder,
                    textColor: AppColors.textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                ),
                if (hasNext) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogBtn(
                      label: 'Next Level',
                      color: AppColors.cyan,
                      textColor: AppColors.bg,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/game/pour-match?level=${currentLevel + 1}');
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _DialogBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _IconBtn({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: color ?? AppColors.textPrimary, size: 18),
      ),
    );
  }
}
