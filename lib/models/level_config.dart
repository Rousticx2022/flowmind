import 'package:flutter/material.dart';
import 'tube.dart';
import '../app/theme.dart';

class PourMatchLevel {
  final int number;
  final String title;
  final String difficulty;
  final List<Tube> tubes;

  const PourMatchLevel({
    required this.number,
    required this.title,
    required this.difficulty,
    required this.tubes,
  });
}

// shorthand
Color _c(int i) => AppColors.liquids[i];

final List<PourMatchLevel> pourMatchLevels = [
  // ── Level 1 ── 2 colors, very easy intro ──────────────────────────────
  PourMatchLevel(
    number: 1,
    title: 'Warm Up',
    difficulty: 'Easy',
    tubes: [
      Tube.filled([_c(0), _c(1), _c(0), _c(1)]),
      Tube.filled([_c(1), _c(0), _c(1), _c(0)]),
      const Tube(),
      const Tube(),
    ],
  ),

  // ── Level 2 ── 3 colors ────────────────────────────────────────────────
  PourMatchLevel(
    number: 2,
    title: 'Color Sort',
    difficulty: 'Easy',
    tubes: [
      Tube.filled([_c(0), _c(1), _c(2), _c(0)]),
      Tube.filled([_c(2), _c(0), _c(1), _c(2)]),
      Tube.filled([_c(1), _c(2), _c(0), _c(1)]),
      const Tube(),
      const Tube(),
    ],
  ),

  // ── Level 3 ── 4 colors ────────────────────────────────────────────────
  PourMatchLevel(
    number: 3,
    title: 'Rising Tide',
    difficulty: 'Medium',
    tubes: [
      Tube.filled([_c(0), _c(1), _c(2), _c(3)]),
      Tube.filled([_c(3), _c(2), _c(1), _c(0)]),
      Tube.filled([_c(1), _c(3), _c(0), _c(2)]),
      Tube.filled([_c(2), _c(0), _c(3), _c(1)]),
      const Tube(),
      const Tube(),
    ],
  ),

  // ── Level 4 ── 5 colors ────────────────────────────────────────────────
  PourMatchLevel(
    number: 4,
    title: 'Deep Currents',
    difficulty: 'Medium',
    tubes: [
      Tube.filled([_c(0), _c(4), _c(2), _c(3)]),
      Tube.filled([_c(3), _c(1), _c(4), _c(0)]),
      Tube.filled([_c(1), _c(3), _c(0), _c(2)]),
      Tube.filled([_c(2), _c(0), _c(3), _c(1)]),
      Tube.filled([_c(4), _c(2), _c(1), _c(4)]),
      const Tube(),
      const Tube(),
    ],
  ),

  // ── Level 5 ── 6 colors ────────────────────────────────────────────────
  PourMatchLevel(
    number: 5,
    title: 'Vortex',
    difficulty: 'Hard',
    tubes: [
      Tube.filled([_c(0), _c(5), _c(2), _c(3)]),
      Tube.filled([_c(3), _c(1), _c(4), _c(0)]),
      Tube.filled([_c(5), _c(3), _c(0), _c(2)]),
      Tube.filled([_c(2), _c(0), _c(3), _c(1)]),
      Tube.filled([_c(4), _c(2), _c(1), _c(5)]),
      Tube.filled([_c(1), _c(4), _c(5), _c(4)]),
      const Tube(),
      const Tube(),
    ],
  ),
];
