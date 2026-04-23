import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _OceanBgPainter(_bgCtrl.value),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Header ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.cyan.withOpacity(0.4)),
                            ),
                            child: const Center(
                              child: Text('💧',
                                  style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'FLOWMIND',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Train your\nbrain.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Fluid puzzles for every age',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Brain skill tags ───────────────────────────────
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: const [
                      _SkillTag('Spatial Reasoning', AppColors.cyan),
                      _SkillTag('Memory', AppColors.mint),
                      _SkillTag('Logic', AppColors.gold),
                      _SkillTag('Focus', AppColors.coral),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Game cards ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.85,
                      children: const [
                        _GameCard(
                          emoji: '🧪',
                          title: 'Pour Match',
                          subtitle: 'Sort colored\nliquids by hue',
                          color: AppColors.cyan,
                          route: '/game/pour-match',
                          skills: ['Spatial', 'Logic'],
                          isLive: true,
                        ),
                        _GameCard(
                          emoji: '🧠',
                          title: 'Memory Flow',
                          subtitle: 'Replay the\npour sequence',
                          color: AppColors.mint,
                          route: '/game/memory-flow',
                          skills: ['Memory', 'Focus'],
                          isLive: true,
                        ),
                        _GameCard(
                          emoji: '⚡',
                          title: 'Reaction Rush',
                          subtitle: 'Tilt to catch\ndroplets in time',
                          color: AppColors.gold,
                          route: '/game/reaction-rush',
                          skills: ['Reaction', 'Focus'],
                          isLive: true,
                        ),
                        _GameCard(
                          emoji: '⚗️',
                          title: 'Volume Logic',
                          subtitle: 'Measure exact\namounts with jugs',
                          color: AppColors.coral,
                          route: '/game/volume-logic',
                          skills: ['Logic', 'Spatial'],
                          isLive: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skill Tag ──────────────────────────────────────────────────────────────
class _SkillTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SkillTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Game Card ──────────────────────────────────────────────────────────────
class _GameCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  final List<String> skills;
  final bool isLive;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
    required this.skills,
    required this.isLive,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.go(widget.route);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isLive
                  ? widget.color.withOpacity(0.35)
                  : AppColors.cardBorder,
              width: widget.isLive ? 1.5 : 1,
            ),
            boxShadow: widget.isLive
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji + lock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(widget.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  if (!widget.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mint.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.isLive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // Skill chips
              Wrap(
                spacing: 4,
                children: widget.skills.map((s) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color: widget.isLive
                            ? widget.color
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated Ocean Background ──────────────────────────────────────────────
class _OceanBgPainter extends CustomPainter {
  final double phase;
  _OceanBgPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A0E1F), Color(0xFF060810)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Animated flowing waves at bottom
    for (int w = 0; w < 3; w++) {
      final waveOffset = w * 0.33;
      final wavePaint = Paint()
        ..color = const Color(0xFF00D4FF).withOpacity(0.025 - w * 0.006)
        ..style = PaintingStyle.fill;

      final path = Path();
      final yBase = size.height * (0.68 + w * 0.1);
      path.moveTo(0, size.height);
      path.lineTo(0, yBase);

      const steps = 40;
      for (int s = 0; s <= steps; s++) {
        final x = size.width * s / steps;
        final y = yBase +
            sin((phase + waveOffset) * 2 * pi + s * pi / 6) * 18 +
            sin((phase + waveOffset) * 2 * pi * 1.5 + s * pi / 4) * 10;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, wavePaint);
    }

    // Floating glow circles
    final glowPositions = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.5, size.height * 0.55),
    ];
    final glowColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF4DFFC3),
      const Color(0xFF4D9FFF),
    ];

    for (int g = 0; g < glowPositions.length; g++) {
      final drift = sin(phase * 2 * pi + g * 2.1) * 8;
      final glowPaint = Paint()
        ..color = glowColors[g].withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(
        glowPositions[g].translate(0, drift),
        80,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_OceanBgPainter old) => old.phase != phase;
}
