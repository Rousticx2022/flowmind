import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ── Jug model ──────────────────────────────────────────────────────────────

class Jug {
  final String label;
  final int capacity;
  final int current;

  const Jug({required this.label, required this.capacity, this.current = 0});

  Jug copyWith({int? current}) =>
      Jug(label: label, capacity: capacity, current: current ?? this.current);

  bool get isEmpty => current == 0;
  bool get isFull => current == capacity;
  double get fillRatio => capacity == 0 ? 0 : current / capacity;
  int get emptySpace => capacity - current;
}

// ── Level config ───────────────────────────────────────────────────────────

class VolumeLevel {
  final int number;
  final String title;
  final String difficulty;
  final List<Jug> startJugs;   // initial fill states
  final int target;             // goal amount in ANY jug
  final String hint;

  const VolumeLevel({
    required this.number,
    required this.title,
    required this.difficulty,
    required this.startJugs,
    required this.target,
    required this.hint,
  });
}

final List<VolumeLevel> volumeLevels = [
  VolumeLevel(
    number: 1,
    title: 'Die Hard Classic',
    difficulty: 'Easy',
    startJugs: [
      const Jug(label: '3L', capacity: 3),
      const Jug(label: '5L', capacity: 5),
    ],
    target: 4,
    hint: 'Fill 5L → pour into 3L → empty 3L → pour remainder → fill 5L again → top up 3L',
  ),
  VolumeLevel(
    number: 2,
    title: 'Triple Trouble',
    difficulty: 'Easy',
    startJugs: [
      const Jug(label: '3L', capacity: 3),
      const Jug(label: '5L', capacity: 5),
      const Jug(label: '8L', capacity: 8, current: 8),
    ],
    target: 4,
    hint: 'Start with the 8L full. Pour between jugs to isolate 4L.',
  ),
  VolumeLevel(
    number: 3,
    title: 'Odd Measures',
    difficulty: 'Medium',
    startJugs: [
      const Jug(label: '4L', capacity: 4),
      const Jug(label: '6L', capacity: 6),
      const Jug(label: '9L', capacity: 9, current: 9),
    ],
    target: 7,
    hint: 'Think about what 9 - 6 + 4 equals...',
  ),
  VolumeLevel(
    number: 4,
    title: 'The Halving',
    difficulty: 'Medium',
    startJugs: [
      const Jug(label: '7L', capacity: 7),
      const Jug(label: '11L', capacity: 11, current: 11),
    ],
    target: 6,
    hint: 'Fill 7L from 11L repeatedly and track remainders.',
  ),
  VolumeLevel(
    number: 5,
    title: 'Prime Time',
    difficulty: 'Hard',
    startJugs: [
      const Jug(label: '3L', capacity: 3),
      const Jug(label: '7L', capacity: 7),
      const Jug(label: '5L', capacity: 5, current: 5),
    ],
    target: 6,
    hint: 'No infinite source — work only with what you have.',
  ),
];

// ── State ──────────────────────────────────────────────────────────────────

enum JugAction { fill, empty }

class VolumeLogicState {
  final List<Jug> jugs;
  final int moves;
  final bool isSolved;
  final int? selectedJug;          // index for pour-between-jugs
  final List<List<Jug>> history;   // undo stack

  const VolumeLogicState({
    required this.jugs,
    this.moves = 0,
    this.isSolved = false,
    this.selectedJug,
    this.history = const [],
  });

  VolumeLogicState copyWith({
    List<Jug>? jugs,
    int? moves,
    bool? isSolved,
    Object? selectedJug = _s,
    List<List<Jug>>? history,
  }) =>
      VolumeLogicState(
        jugs: jugs ?? this.jugs,
        moves: moves ?? this.moves,
        isSolved: isSolved ?? this.isSolved,
        selectedJug: selectedJug == _s ? this.selectedJug : selectedJug as int?,
        history: history ?? this.history,
      );
}

const _s = Object();

// ── Notifier ───────────────────────────────────────────────────────────────

class VolumeLogicNotifier extends StateNotifier<VolumeLogicState> {
  final int levelIndex;
  final int target;

  VolumeLogicNotifier(this.levelIndex)
      : target = volumeLevels[levelIndex].target,
        super(VolumeLogicState(
          jugs: List.from(volumeLevels[levelIndex].startJugs),
        ));

  void fill(int index) {
    final jug = state.jugs[index];
    if (jug.isFull) return;
    _update(index, jug.copyWith(current: jug.capacity));
  }

  void empty(int index) {
    final jug = state.jugs[index];
    if (jug.isEmpty) return;
    _update(index, jug.copyWith(current: 0));
  }

  // Pour selected → index, or select if none selected
  void tapJug(int index) {
    if (state.selectedJug == null) {
      // First tap: select if not empty
      if (state.jugs[index].isEmpty) return;
      state = state.copyWith(selectedJug: index);
      return;
    }

    final fromIdx = state.selectedJug!;

    if (fromIdx == index) {
      state = state.copyWith(selectedJug: null);
      return;
    }

    // Pour from → to
    final from = state.jugs[fromIdx];
    final to = state.jugs[index];

    if (from.isEmpty || to.isFull) {
      state = state.copyWith(selectedJug: null);
      return;
    }

    final snapshot = List<Jug>.from(state.jugs);
    final pour = from.current < to.emptySpace ? from.current : to.emptySpace;
    final newJugs = List<Jug>.from(state.jugs);
    newJugs[fromIdx] = from.copyWith(current: from.current - pour);
    newJugs[index] = to.copyWith(current: to.current + pour);

    final solved = newJugs.any((j) => j.current == target);

    state = state.copyWith(
      jugs: newJugs,
      moves: state.moves + 1,
      isSolved: solved,
      selectedJug: null,
      history: [...state.history, snapshot],
    );
  }

  void _update(int index, Jug newJug) {
    final snapshot = List<Jug>.from(state.jugs);
    final newJugs = List<Jug>.from(state.jugs);
    newJugs[index] = newJug;
    final solved = newJugs.any((j) => j.current == target);
    state = state.copyWith(
      jugs: newJugs,
      moves: state.moves + 1,
      isSolved: solved,
      selectedJug: null,
      history: [...state.history, snapshot],
    );
  }

  void undo() {
    if (state.history.isEmpty) return;
    final prev = state.history.last;
    state = state.copyWith(
      jugs: prev,
      moves: state.moves > 0 ? state.moves - 1 : 0,
      isSolved: false,
      selectedJug: null,
      history: state.history.sublist(0, state.history.length - 1),
    );
  }

  void reset() {
    state = VolumeLogicState(
      jugs: List.from(volumeLevels[levelIndex].startJugs),
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final volumeLogicProvider =
    StateNotifierProvider.family<VolumeLogicNotifier, VolumeLogicState, int>(
  (ref, levelIndex) => VolumeLogicNotifier(levelIndex),
);
