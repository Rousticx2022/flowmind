import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../models/tube.dart';
import '../../../models/level_config.dart';

// ── State ──────────────────────────────────────────────────────────────────
class PourMatchState {
  final List<Tube> tubes;
  final int? selectedIndex;
  final int moves;
  final bool isComplete;
  final List<List<Tube>> history; // undo stack

  const PourMatchState({
    required this.tubes,
    this.selectedIndex,
    this.moves = 0,
    this.isComplete = false,
    this.history = const [],
  });

  PourMatchState copyWith({
    List<Tube>? tubes,
    Object? selectedIndex = _sentinel,
    int? moves,
    bool? isComplete,
    List<List<Tube>>? history,
  }) {
    return PourMatchState(
      tubes: tubes ?? this.tubes,
      selectedIndex: selectedIndex == _sentinel
          ? this.selectedIndex
          : selectedIndex as int?,
      moves: moves ?? this.moves,
      isComplete: isComplete ?? this.isComplete,
      history: history ?? this.history,
    );
  }
}

const _sentinel = Object();

// ── Notifier ───────────────────────────────────────────────────────────────
class PourMatchNotifier extends StateNotifier<PourMatchState> {
  PourMatchNotifier(int levelIndex)
      : super(PourMatchState(
          tubes: List.from(pourMatchLevels[levelIndex].tubes),
        ));

  void tap(int index) {
    final current = state;
    final tubes = current.tubes;

    // Nothing selected yet → select this tube (only if not empty)
    if (current.selectedIndex == null) {
      if (tubes[index].isEmpty) return;
      state = current.copyWith(selectedIndex: index);
      return;
    }

    final fromIdx = current.selectedIndex!;

    // Tapped same tube → deselect
    if (fromIdx == index) {
      state = current.copyWith(selectedIndex: null);
      return;
    }

    final from = tubes[fromIdx];
    final to = tubes[index];

    // Can't pour
    if (!to.canReceiveFrom(from)) {
      // Switch selection to newly tapped tube if it has liquid
      if (!tubes[index].isEmpty) {
        state = current.copyWith(selectedIndex: index);
      } else {
        state = current.copyWith(selectedIndex: null);
      }
      return;
    }

    // Snapshot for undo
    final snapshot = List<Tube>.from(tubes);

    // Execute pour
    final (newFrom, newTo) = Tube.pour(from, to);
    final newTubes = List<Tube>.from(tubes);
    newTubes[fromIdx] = newFrom;
    newTubes[index] = newTo;

    final complete = newTubes.every(
      (t) => t.isEmpty || t.isComplete,
    );

    state = current.copyWith(
      tubes: newTubes,
      selectedIndex: null,
      moves: current.moves + 1,
      isComplete: complete,
      history: [...current.history, snapshot],
    );
  }

  void undo() {
    if (state.history.isEmpty) return;
    final prev = state.history.last;
    state = state.copyWith(
      tubes: prev,
      selectedIndex: null,
      moves: state.moves > 0 ? state.moves - 1 : 0,
      isComplete: false,
      history: state.history.sublist(0, state.history.length - 1),
    );
  }

  void reset(int levelIndex) {
    state = PourMatchState(
      tubes: List.from(pourMatchLevels[levelIndex].tubes),
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────
final pourMatchProvider =
    StateNotifierProvider.family<PourMatchNotifier, PourMatchState, int>(
  (ref, levelIndex) => PourMatchNotifier(levelIndex),
);
