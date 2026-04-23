import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ── Types ──────────────────────────────────────────────────────────────────

enum MemoryPhase { idle, watching, recalling, success, fail }

class PourStep {
  final int from;
  final int to;
  const PourStep(this.from, this.to);
}

class MemoryFlowState {
  final MemoryPhase phase;
  final List<PourStep> sequence;
  final List<PourStep> playerInput;
  final int round;
  final int score;
  final int? highlightFrom; // tube glowing during playback
  final int? highlightTo;
  final int lives;
  final bool showSuccess; // flash feedback

  const MemoryFlowState({
    this.phase = MemoryPhase.idle,
    this.sequence = const [],
    this.playerInput = const [],
    this.round = 1,
    this.score = 0,
    this.highlightFrom,
    this.highlightTo,
    this.lives = 3,
    this.showSuccess = false,
  });

  MemoryFlowState copyWith({
    MemoryPhase? phase,
    List<PourStep>? sequence,
    List<PourStep>? playerInput,
    int? round,
    int? score,
    Object? highlightFrom = _s,
    Object? highlightTo = _s,
    int? lives,
    bool? showSuccess,
  }) =>
      MemoryFlowState(
        phase: phase ?? this.phase,
        sequence: sequence ?? this.sequence,
        playerInput: playerInput ?? this.playerInput,
        round: round ?? this.round,
        score: score ?? this.score,
        highlightFrom: highlightFrom == _s ? this.highlightFrom : highlightFrom as int?,
        highlightTo: highlightTo == _s ? this.highlightTo : highlightTo as int?,
        lives: lives ?? this.lives,
        showSuccess: showSuccess ?? this.showSuccess,
      );

  int get expectedNext => playerInput.length;
  bool get isComplete => playerInput.length == sequence.length;
}

const _s = Object();

// ── Tube colors for display (fixed 4-tube set) ─────────────────────────────

const kTubeCount = 4;
const List<List<Color>> kTubeBaseColors = [
  [Color(0xFFFF4D4D), Color(0xFF4D9FFF)],
  [Color(0xFF4DFF91), Color(0xFFFFD84D)],
  [Color(0xFFBF4DFF), Color(0xFFFF4D4D)],
  [Color(0xFF4D9FFF), Color(0xFF4DFF91)],
];

// ── Notifier ───────────────────────────────────────────────────────────────

class MemoryFlowNotifier extends StateNotifier<MemoryFlowState> {
  MemoryFlowNotifier() : super(const MemoryFlowState());

  final _rng = Random();
  Timer? _playbackTimer;

  // Start / next round
  void startRound() {
    _playbackTimer?.cancel();

    // Build sequence: round + 1 steps (round 1 = 2 steps, round 2 = 3, etc.)
    final seq = <PourStep>[];
    int? lastFrom;
    for (int i = 0; i < state.round + 1; i++) {
      int from, to;
      do {
        from = _rng.nextInt(kTubeCount);
        to = _rng.nextInt(kTubeCount);
      } while (from == to || from == lastFrom);
      lastFrom = from;
      seq.add(PourStep(from, to));
    }

    state = state.copyWith(
      phase: MemoryPhase.watching,
      sequence: seq,
      playerInput: [],
      highlightFrom: null,
      highlightTo: null,
      showSuccess: false,
    );

    _playSequence(seq);
  }

  void _playSequence(List<PourStep> seq) {
    const stepMs = 900;
    const showMs = 600;

    for (int i = 0; i < seq.length; i++) {
      // Show highlight
      Future.delayed(Duration(milliseconds: i * stepMs), () {
        if (!mounted) return;
        state = state.copyWith(
          highlightFrom: seq[i].from,
          highlightTo: seq[i].to,
        );
      });
      // Clear highlight
      Future.delayed(Duration(milliseconds: i * stepMs + showMs), () {
        if (!mounted) return;
        state = state.copyWith(
          highlightFrom: null,
          highlightTo: null,
        );
      });
    }

    // Switch to recall phase
    Future.delayed(Duration(milliseconds: seq.length * stepMs + 200), () {
      if (!mounted) return;
      state = state.copyWith(phase: MemoryPhase.recalling);
    });
  }

  void tapTube(int index) {
    if (state.phase != MemoryPhase.recalling) return;

    final expected = state.sequence[state.expectedNext];

    // First tap in a step → from tube
    final inputSoFar = state.playerInput;

    // We track (from, to) pairs; player taps from then to
    // We use a simpler UX: player taps tubes in order matching the sequence
    // Each tap corresponds to one position in the flattened sequence
    // Sequence = [(from0,to0),(from1,to1)...]
    // Player taps: from0, to0, from1, to1...

    final flatIndex = inputSoFar.length * 2 + _pendingTap;

    // Determine what we expect at this flat position
    final stepIndex = flatIndex ~/ 2;
    final isFromTap = flatIndex % 2 == 0;
    final expectedStep = state.sequence[stepIndex];
    final expectedTube = isFromTap ? expectedStep.from : expectedStep.to;

    if (index != expectedTube) {
      // Wrong!
      final newLives = state.lives - 1;
      state = state.copyWith(
        phase: newLives <= 0 ? MemoryPhase.fail : MemoryPhase.recalling,
        lives: newLives,
        playerInput: [],
        highlightFrom: index, // flash wrong tube
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) state = state.copyWith(highlightFrom: null);
        if (mounted && newLives > 0) {
          // Let them retry from start of sequence
          state = state.copyWith(playerInput: []);
          _pendingTap = 0;
        }
      });
      return;
    }

    // Correct tap
    state = state.copyWith(highlightFrom: index, showSuccess: true);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) state = state.copyWith(highlightFrom: null, showSuccess: false);
    });

    if (isFromTap) {
      _pendingTap = 1; // waiting for "to" tap
    } else {
      _pendingTap = 0;
      final newInput = [...inputSoFar, expectedStep];
      if (newInput.length == state.sequence.length) {
        // Round complete!
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          state = state.copyWith(
            phase: MemoryPhase.success,
            playerInput: newInput,
            score: state.score + state.round * 10,
          );
        });
      } else {
        state = state.copyWith(playerInput: newInput);
      }
    }
  }

  int _pendingTap = 0; // 0=waiting for "from", 1=waiting for "to"

  void nextRound() {
    state = state.copyWith(round: state.round + 1);
    startRound();
  }

  void restart() {
    _playbackTimer?.cancel();
    state = const MemoryFlowState();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final memoryFlowProvider =
    StateNotifierProvider<MemoryFlowNotifier, MemoryFlowState>(
  (ref) => MemoryFlowNotifier(),
);
