import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'components/rush_components.dart';
import 'package:flutter/material.dart';

const kGameDuration = 45;

enum RushPhase { idle, playing, gameOver }

class ReactionRushState {
  final RushPhase phase;
  final int score;
  final int lives;
  final int timeLeft;
  final int combo;

  const ReactionRushState({
    this.phase = RushPhase.idle,
    this.score = 0,
    this.lives = 5,
    this.timeLeft = kGameDuration,
    this.combo = 0,
  });

  ReactionRushState copyWith({
    RushPhase? phase,
    int? score,
    int? lives,
    int? timeLeft,
    int? combo,
  }) =>
      ReactionRushState(
        phase: phase ?? this.phase,
        score: score ?? this.score,
        lives: lives ?? this.lives,
        timeLeft: timeLeft ?? this.timeLeft,
        combo: combo ?? this.combo,
      );
}

class ReactionRushNotifier extends StateNotifier<ReactionRushState> {
  ReactionRushNotifier() : super(const ReactionRushState());

  Timer? _countdownTimer;

  void startGame() {
    state = const ReactionRushState(phase: RushPhase.playing);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (state.phase != RushPhase.playing) { t.cancel(); return; }
      final next = state.timeLeft - 1;
      if (next <= 0) {
        t.cancel();
        state = state.copyWith(phase: RushPhase.gameOver, timeLeft: 0);
      } else {
        state = state.copyWith(timeLeft: next);
      }
    });
  }

  void recordResult(bool correct) {
    if (state.phase != RushPhase.playing) return;
    if (correct) {
      final bonus = state.combo >= 3 ? 2 : 1;
      state = state.copyWith(
        score: state.score + 10 * bonus,
        combo: state.combo + 1,
      );
    } else {
      final newLives = state.lives - 1;
      if (newLives <= 0) {
        _countdownTimer?.cancel();
        state = state.copyWith(lives: 0, phase: RushPhase.gameOver, combo: 0);
      } else {
        state = state.copyWith(lives: newLives, combo: 0);
      }
    }
  }

  void restart() {
    _countdownTimer?.cancel();
    state = const ReactionRushState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final reactionRushProvider =
    StateNotifierProvider<ReactionRushNotifier, ReactionRushState>(
  (ref) => ReactionRushNotifier(),
);
