import 'package:flutter/material.dart';

const int kTubeCapacity = 4;

class Tube {
  final List<Color> segments; // bottom to top

  const Tube({this.segments = const []});

  Tube.filled(List<Color> colors) : segments = List.unmodifiable(colors);

  Tube copyWith({List<Color>? segments}) =>
      Tube(segments: segments ?? List.from(this.segments));

  bool get isEmpty => segments.isEmpty;
  bool get isFull => segments.length >= kTubeCapacity;

  /// All 4 slots filled with the same color
  bool get isComplete =>
      segments.length == kTubeCapacity &&
      segments.every((c) => c.value == segments.first.value);

  Color? get topColor => isEmpty ? null : segments.last;

  int get fillCount => segments.length;
  int get emptySlots => kTubeCapacity - fillCount;

  /// Count of consecutive top-color segments that would pour together
  int get topColorCount {
    if (isEmpty) return 0;
    final top = topColor!;
    int count = 0;
    for (int i = segments.length - 1; i >= 0; i--) {
      if (segments[i].value == top.value) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool canReceiveFrom(Tube other) {
    if (other.isEmpty) return false;
    if (isFull) return false;
    if (isEmpty) return true;
    return topColor!.value == other.topColor!.value;
  }

  /// Pour as many top-matching segments as possible into [target]
  /// Returns (updatedSource, updatedTarget)
  static (Tube, Tube) pour(Tube source, Tube target) {
    assert(target.canReceiveFrom(source));

    final srcSegs = List<Color>.from(source.segments);
    final dstSegs = List<Color>.from(target.segments);

    final pourColor = srcSegs.last;
    int canPour = source.topColorCount;
    int canReceive = target.emptySlots;
    int amount = canPour < canReceive ? canPour : canReceive;

    for (int i = 0; i < amount; i++) {
      dstSegs.add(pourColor);
      srcSegs.removeLast();
    }

    return (
      Tube(segments: List.unmodifiable(srcSegs)),
      Tube(segments: List.unmodifiable(dstSegs)),
    );
  }
}
