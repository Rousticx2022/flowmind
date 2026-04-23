import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../flame/effects_game.dart';
import 'memory_flow_provider.dart';

class MemoryFlowScreen extends ConsumerStatefulWidget {
  const MemoryFlowScreen({super.key});

  @override
  ConsumerState<MemoryFlowScreen> createState() => _MemoryFlowScreenState();
}

class _MemoryFlowScreenState extends ConsumerState<MemoryFlowScreen> {
  late final FlowEffectsGame _effectsGame;
  int _prevScore = 0;
  int _prevLives = 3;

  @override
  void initState() {
    super.initState();
    _effectsGame = FlowEffectsGame();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryFlowProvider);
    final notifier = ref.read(memoryFlowProvider.notifier);

    // Score just went up → correct!
    if (state.score > _prevScore) {
      _prevScore = state.score;
      final size = MediaQuery.of(context).size;
      _effectsGame.spawnFeedback(Offset(size.width / 2, size.height * 0.55), true);
    }

    // Lives went down → wrong tap
    if (state.lives < _prevLives) {
      _prevLives = state.lives;
      final size = MediaQuery.of(context).size;
      _effectsGame.spawnFeedback(Offset(size.width / 2, size.height * 0.55), false);
    }

    // Round success → celebration
    if (state.phase == MemoryPhase.success) {
      _effectsGame.spawnCelebration(MediaQuery.of(context).size);
    }

    _prevScore = state.score;
    _prevLives = state.lives;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF071A14), Color(0xFF060810)]),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    state: state,
                    onBack: () {
                      notifier.restart();
                      context.go('/');
                    },
                  ),
                  const SizedBox(height: 8),
                  _StatusBanner(state: state),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _TubesArea(state: state, onTap: notifier.tapTube),
                  ),
                  _BottomPanel(state: state, notifier: notifier),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(child: GameWidget(game: _effectsGame)),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final MemoryFlowState state;
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
                const Text(
                  'MEMORY FLOW',
                  style: TextStyle(color: AppColors.mint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2),
                ),
                Text(
                  'Round ${state.round}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mint.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.mint, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${state.score}',
                  style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.favorite_rounded, color: i < state.lives ? AppColors.coral : AppColors.textMuted, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Banner ──────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final MemoryFlowState state;
  const _StatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state.phase) {
      MemoryPhase.idle => ('Press START to play', AppColors.textSecondary),
      MemoryPhase.watching => ('Watch carefully...', AppColors.gold),
      MemoryPhase.recalling => ('Your turn! Tap from → to', AppColors.mint),
      MemoryPhase.success => ('Perfect! 🎉', AppColors.mint),
      MemoryPhase.fail => ('Game Over 💀', AppColors.coral),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(state.phase),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

// ── Tubes Area ─────────────────────────────────────────────────────────────
class _TubesArea extends StatelessWidget {
  final MemoryFlowState state;
  final void Function(int) onTap;
  const _TubesArea({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(kTubeCount, (i) {
          return _MemoryTube(
            index: i,
            colors: kTubeBaseColors[i],
            isHighlightedFrom: state.highlightFrom == i,
            isHighlightedTo: state.highlightTo == i,
            isInteractive: state.phase == MemoryPhase.recalling,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _MemoryTube extends StatefulWidget {
  final int index;
  final List<Color> colors;
  final bool isHighlightedFrom;
  final bool isHighlightedTo;
  final bool isInteractive;
  final VoidCallback onTap;
  const _MemoryTube({
    required this.index,
    required this.colors,
    required this.isHighlightedFrom,
    required this.isHighlightedTo,
    required this.isInteractive,
    required this.onTap,
  });

  @override
  State<_MemoryTube> createState() => _MemoryTubeState();
}

class _MemoryTubeState extends State<_MemoryTube> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulse = Tween(begin: 1.0, end: 1.07).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_MemoryTube old) {
    super.didUpdateWidget(old);
    final isHL = widget.isHighlightedFrom || widget.isHighlightedTo;
    final wasHL = old.isHighlightedFrom || old.isHighlightedTo;
    if (isHL && !wasHL) _ctrl.repeat(reverse: true);
    if (!isHL && wasHL) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _accents = [AppColors.cyan, AppColors.mint, AppColors.gold, AppColors.coral];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[widget.index];
    final isHL = widget.isHighlightedFrom || widget.isHighlightedTo;

    return GestureDetector(
      onTap: widget.isInteractive ? widget.onTap : null,
      child: ScaleTransition(
        scale: _pulse,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arrow indicator above tube
            SizedBox(
              height: 28,
              child: isHL
                  ? Icon(
                      widget.isHighlightedFrom ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: widget.isHighlightedFrom ? AppColors.gold : AppColors.mint,
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(height: 4),

            // Tube body
            Container(
              width: 62,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(31),
                border: Border.all(color: isHL ? accent : accent.withOpacity(0.3), width: isHL ? 2.5 : 1.5),
                boxShadow: isHL ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 22, spreadRadius: 2)] : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: Column(
                  children: [
                    Expanded(child: Container(color: widget.colors[0].withOpacity(0.9))),
                    Expanded(child: Container(color: widget.colors[1].withOpacity(0.9))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Number badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: (widget.isInteractive ? accent : AppColors.surface).withOpacity(widget.isInteractive ? 0.15 : 1),
                shape: BoxShape.circle,
                border: Border.all(color: widget.isInteractive ? accent.withOpacity(0.5) : AppColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(color: widget.isInteractive ? accent : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Panel ───────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final MemoryFlowState state;
  final MemoryFlowNotifier notifier;
  const _BottomPanel({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: switch (state.phase) {
        MemoryPhase.idle => _BigBtn(label: 'START', color: AppColors.mint, icon: Icons.play_arrow_rounded, onTap: notifier.startRound),
        MemoryPhase.watching => _SequenceDisplay(state: state),
        MemoryPhase.recalling => _RecallProgress(state: state),
        MemoryPhase.success => _BigBtn(label: 'NEXT ROUND', color: AppColors.mint, icon: Icons.arrow_forward_rounded, onTap: notifier.nextRound),
        MemoryPhase.fail => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Final Score: ${state.score}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _BigBtn(
              label: 'PLAY AGAIN',
              color: AppColors.coral,
              icon: Icons.refresh_rounded,
              onTap: () {
                notifier.restart();
                notifier.startRound();
              },
            ),
          ],
        ),
      },
    );
  }
}

class _SequenceDisplay extends StatelessWidget {
  final MemoryFlowState state;
  const _SequenceDisplay({required this.state});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Sequence', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: state.sequence
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      _Badge('${s.from + 1}', AppColors.gold),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted, size: 12),
                      _Badge('${s.to + 1}', AppColors.mint),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RecallProgress extends StatelessWidget {
  final MemoryFlowState state;
  const _RecallProgress({required this.state});
  @override
  Widget build(BuildContext context) {
    final done = state.playerInput.length;
    final total = state.sequence.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Step ${done + 1} of $total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: done / total,
            minHeight: 8,
            backgroundColor: AppColors.cardBorder,
            valueColor: const AlwaysStoppedAnimation(AppColors.mint),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      shape: BoxShape.circle,
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Center(
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _BigBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _BigBtn({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.bg, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1.5),
          ),
        ],
      ),
    ),
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
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 18),
    ),
  );
}
