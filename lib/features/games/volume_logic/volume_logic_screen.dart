import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../flame/effects_game.dart';
import 'volume_logic_provider.dart';

class VolumeLogicScreen extends ConsumerStatefulWidget {
  final int level;
  const VolumeLogicScreen({super.key, this.level = 1});

  @override
  ConsumerState<VolumeLogicScreen> createState() => _VolumeLogicScreenState();
}

class _VolumeLogicScreenState extends ConsumerState<VolumeLogicScreen> {
  late final FlowEffectsGame _effectsGame;
  int _prevMoves = 0;
  bool _wasSolved = false;

  int get _levelIdx =>
      (widget.level - 1).clamp(0, volumeLevels.length - 1);
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _effectsGame = FlowEffectsGame();
  }

  @override
  Widget build(BuildContext context) {
    final levelData = volumeLevels[_levelIdx];
    final state = ref.watch(volumeLogicProvider(_levelIdx));
    final notifier = ref.read(volumeLogicProvider(_levelIdx).notifier);

    // Pour effect when move count increases
    if (state.moves > _prevMoves) {
      _prevMoves = state.moves;
      final size = MediaQuery.of(context).size;
      final color = const Color(0xFF4D9FFF);
      final from = Offset(size.width * 0.35, size.height * 0.45);
      final to = Offset(size.width * 0.65, size.height * 0.55);
      _effectsGame.spawnPourArc(from, to, color, count: 20);
    }

    // Solved celebration
    if (state.isSolved && !_wasSolved) {
      _wasSolved = true;
      _effectsGame.spawnCelebration(MediaQuery.of(context).size);
    }
    if (!state.isSolved) _wasSolved = false;

    if (state.isSolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWinDialog(context, state.moves, levelData);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0A00), Color(0xFF060810)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _TopBar(
                    levelData: levelData,
                    moves: state.moves,
                    canUndo: state.history.isNotEmpty,
                    onUndo: notifier.undo,
                    onReset: notifier.reset,
                    onBack: () => context.go('/'),
                  ),
                  const SizedBox(height: 12),
                  _TargetBanner(target: notifier.target, jugs: state.jugs),
                  const SizedBox(height: 8),
                  if (state.selectedJug != null)
                    _InfoChip('Tube ${state.selectedJug! + 1} selected — tap destination', AppColors.coral)
                  else
                    _InfoChip('Tap a jug to pour  •  Hold to fill/empty', AppColors.textMuted),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: state.jugs.asMap().entries.map((e) {
                      final idx = e.key;
                      final jug = e.value;
                      return _JugWidget(
                        jug: jug,
                        isSelected: state.selectedJug == idx,
                        isSolved: state.isSolved && jug.current == notifier.target,
                        onTap: () => notifier.tapJug(idx),
                        onFill: () => notifier.fill(idx),
                        onEmpty: () => notifier.empty(idx),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Row(children: [
                          const Icon(Icons.swap_horiz_rounded, color: AppColors.coral, size: 18),
                          const SizedBox(width: 4),
                          Text('${state.moves} ${state.moves == 1 ? 'move' : 'moves'}',
                              style: const TextStyle(color: AppColors.coral,
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ]),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showHint = !_showHint),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(children: [
                              const Icon(Icons.lightbulb_outline_rounded,
                                  color: AppColors.gold, size: 14),
                              const SizedBox(width: 4),
                              Text(_showHint ? 'Hide Hint' : 'Hint',
                                  style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: _showHint
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                              ),
                              child: Text(levelData.hint,
                                  style: const TextStyle(color: AppColors.gold,
                                      fontSize: 13, height: 1.5)),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Flame effects overlay
          Positioned.fill(
            child: IgnorePointer(child: GameWidget(game: _effectsGame)),
          ),
        ],
      ),
    );
  }

  void _showWinDialog(BuildContext ctx, int moves, VolumeLevel level) {
    final hasNext = _levelIdx + 1 < volumeLevels.length;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.coral.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(
                color: AppColors.coral.withOpacity(0.15), blurRadius: 40, spreadRadius: 2)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚗️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text('SOLVED!', style: TextStyle(color: AppColors.coral, fontSize: 26,
                fontWeight: FontWeight.w800, letterSpacing: 3)),
            const SizedBox(height: 8),
            Text('$moves ${moves == 1 ? 'move' : 'moves'} used',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: _DialogBtn(label: 'Menu', color: AppColors.cardBorder,
                  textColor: AppColors.textSecondary,
                  onTap: () { Navigator.pop(ctx); ctx.go('/'); })),
              if (hasNext) ...[
                const SizedBox(width: 12),
                Expanded(child: _DialogBtn(label: 'Next Level', color: AppColors.coral,
                    textColor: Colors.white,
                    onTap: () { Navigator.pop(ctx);
                      ctx.go('/game/volume-logic?level=${_levelIdx + 2}'); })),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Jug Widget ─────────────────────────────────────────────────────────────
class _JugWidget extends StatefulWidget {
  final Jug jug;
  final bool isSelected;
  final bool isSolved;
  final VoidCallback onTap;
  final VoidCallback onFill;
  final VoidCallback onEmpty;

  const _JugWidget({
    required this.jug,
    required this.isSelected,
    required this.isSolved,
    required this.onTap,
    required this.onFill,
    required this.onEmpty,
  });

  @override
  State<_JugWidget> createState() => _JugWidgetState();
}

class _JugWidgetState extends State<_JugWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() { _waveCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isSolved
        ? AppColors.mint
        : widget.isSelected
            ? AppColors.coral
            : const Color(0xFF2A5599);

    const maxH = 200.0;
    const jugW = 74.0;
    final jugH = maxH * (widget.jug.capacity / 11.0).clamp(0.6, 1.0); // scale by capacity

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        // Show action sheet
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.card,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _JugActionSheet(
              jug: widget.jug, onFill: widget.onFill, onEmpty: widget.onEmpty),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label above
          Text(widget.jug.label,
              style: TextStyle(
                  color: accent, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),

          // Jug
          AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              transform: widget.isSelected
                  ? (Matrix4.identity()..translate(0.0, -6.0))
                  : Matrix4.identity(),
              child: CustomPaint(
                size: Size(jugW, jugH),
                painter: _JugPainter(
                  fillRatio: widget.jug.fillRatio,
                  isSelected: widget.isSelected,
                  isSolved: widget.isSolved,
                  wavePhase: _waveCtrl.value * 2 * pi,
                  accent: accent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Current amount
          Text('${widget.jug.current}L',
              style: TextStyle(
                  color: widget.jug.isEmpty ? AppColors.textMuted : accent,
                  fontSize: 15, fontWeight: FontWeight.w800)),
          Text('/ ${widget.jug.capacity}L',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Jug Painter ────────────────────────────────────────────────────────────
class _JugPainter extends CustomPainter {
  final double fillRatio;
  final bool isSelected;
  final bool isSolved;
  final double wavePhase;
  final Color accent;

  const _JugPainter({
    required this.fillRatio,
    required this.isSelected,
    required this.isSolved,
    required this.wavePhase,
    required this.accent,
  });

  static const _wall = 5.0;
  static const _r = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Interior clip
    final inner = Path()
      ..moveTo(_wall, 0)
      ..lineTo(_wall, h - _wall - _r)
      ..arcToPoint(Offset(_wall + _r, h - _wall),
          radius: const Radius.circular(_r), clockwise: true)
      ..lineTo(w - _wall - _r, h - _wall)
      ..arcToPoint(Offset(w - _wall, h - _wall - _r),
          radius: const Radius.circular(_r), clockwise: true)
      ..lineTo(w - _wall, 0)
      ..close();

    canvas.save();
    canvas.clipPath(inner);

    // Dark well
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF070C1A));

    if (fillRatio > 0) {
      final liquidColor = isSolved
          ? const Color(0xFF4DFFC3)
          : const Color(0xFF4D9FFF);
      final fillTop = h - _wall - (h - _wall) * fillRatio;

      // Wave surface
      final wavePath = Path()..moveTo(_wall, h - _wall)..lineTo(_wall, fillTop + 4);
      const steps = 18;
      for (int s = 0; s <= steps; s++) {
        final x = _wall + (w - _wall * 2) * s / steps;
        final y = fillTop + sin(wavePhase + s * pi * 2 / steps) * 4;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(w - _wall, h - _wall);
      wavePath.close();
      canvas.drawPath(wavePath, Paint()..color = liquidColor.withOpacity(0.85));

      // Sheen
      canvas.drawRect(
        Rect.fromLTRB(_wall, fillTop, w - _wall, h - _wall),
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [Colors.white.withOpacity(0.18), Colors.transparent],
        ).createShader(Rect.fromLTRB(_wall, fillTop, w - _wall, h - _wall)),
      );
    }

    canvas.restore();

    // Glass walls
    final outline = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - _r)
      ..arcToPoint(Offset(_r, h), radius: const Radius.circular(_r), clockwise: true)
      ..lineTo(w - _r, h)
      ..arcToPoint(Offset(w, h - _r), radius: const Radius.circular(_r), clockwise: true)
      ..lineTo(w, 0);

    if (isSelected || isSolved) {
      canvas.drawPath(outline,
          Paint()
            ..color = accent.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = _wall);
    }

    canvas.drawPath(outline,
        Paint()
          ..color = isSelected || isSolved ? accent : const Color(0xFF2A3A6A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 : 1.5);

    // Graduation marks
    final markPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1;
    for (int m = 1; m < 5; m++) {
      final y = h - _wall - (h - _wall) * m / 5;
      canvas.drawLine(Offset(w - _wall - 10, y), Offset(w - _wall, y), markPaint);
    }
  }

  @override
  bool shouldRepaint(_JugPainter old) =>
      old.fillRatio != fillRatio ||
      old.isSelected != isSelected ||
      old.isSolved != isSolved ||
      old.wavePhase != wavePhase;
}

// ── Action Sheet ───────────────────────────────────────────────────────────
class _JugActionSheet extends StatelessWidget {
  final Jug jug;
  final VoidCallback onFill;
  final VoidCallback onEmpty;

  const _JugActionSheet(
      {required this.jug, required this.onFill, required this.onEmpty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(jug.label,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${jug.current}L / ${jug.capacity}L',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: _SheetBtn(
              label: 'Fill to Max',
              icon: Icons.water_drop_rounded,
              color: AppColors.cyan,
              enabled: !jug.isFull,
              onTap: () { Navigator.pop(context); onFill(); },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SheetBtn(
              label: 'Empty',
              icon: Icons.delete_outline_rounded,
              color: AppColors.coral,
              enabled: !jug.isEmpty,
              onTap: () { Navigator.pop(context); onEmpty(); },
            ),
          ),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
        ),
      ]),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _SheetBtn({
    required this.label, required this.icon,
    required this.color, required this.enabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: enabled ? color.withOpacity(0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: enabled ? color.withOpacity(0.4) : AppColors.cardBorder),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: enabled ? color : AppColors.textMuted, size: 18),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            color: enabled ? color : AppColors.textMuted,
            fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}

// ── Shared widgets ─────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VolumeLevel levelData;
  final int moves;
  final bool canUndo;
  final VoidCallback onUndo, onReset, onBack;

  const _TopBar({
    required this.levelData, required this.moves,
    required this.canUndo, required this.onUndo,
    required this.onReset, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        _IconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('VOLUME LOGIC',
              style: TextStyle(color: AppColors.coral, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 2)),
          Text(levelData.title,
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _diffColor(levelData.difficulty).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _diffColor(levelData.difficulty).withOpacity(0.4)),
          ),
          child: Text(levelData.difficulty,
              style: TextStyle(color: _diffColor(levelData.difficulty),
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        _IconBtn(
            icon: Icons.undo_rounded,
            onTap: canUndo ? onUndo : null,
            color: canUndo ? AppColors.textPrimary : AppColors.textMuted),
        _IconBtn(icon: Icons.refresh_rounded, onTap: onReset),
      ]),
    );
  }

  Color _diffColor(String d) => switch (d) {
    'Easy' => AppColors.mint, 'Medium' => AppColors.gold, _ => AppColors.coral
  };
}

class _TargetBanner extends StatelessWidget {
  final int target;
  final List<Jug> jugs;
  const _TargetBanner({required this.target, required this.jugs});

  @override
  Widget build(BuildContext context) {
    final achieved = jugs.any((j) => j.current == target);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: achieved ? AppColors.mint.withOpacity(0.12) : AppColors.coral.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: achieved ? AppColors.mint.withOpacity(0.4) : AppColors.coral.withOpacity(0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(achieved ? Icons.check_circle_rounded : Icons.flag_rounded,
              color: achieved ? AppColors.mint : AppColors.coral, size: 16),
          const SizedBox(width: 8),
          Text(
            achieved ? 'Target achieved: ${target}L!' : 'Goal: Get exactly ${target}L in any jug',
            style: TextStyle(
                color: achieved ? AppColors.mint : AppColors.coral,
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoChip(this.text, this.color);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: TextStyle(color: color, fontSize: 12, letterSpacing: 0.3)),
  );
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _DialogBtn({required this.label, required this.color,
      required this.textColor, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Center(child: Text(label, style: TextStyle(
          color: textColor, fontWeight: FontWeight.w700, fontSize: 14))),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  const _IconBtn({required this.icon, this.onTap, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder)),
      child: Icon(icon, color: color ?? AppColors.textPrimary, size: 18),
    ),
  );
}
