import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/tube.dart';
import 'tube_painter.dart';

class TubeWidget extends StatefulWidget {
  final Tube tube;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const TubeWidget({
    super.key,
    required this.tube,
    required this.onTap,
    this.isSelected = false,
    this.width = 58,
    this.height = 210,
  });

  @override
  State<TubeWidget> createState() => _TubeWidgetState();
}

class _TubeWidgetState extends State<TubeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _waveCtrl,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: widget.isSelected
                ? (Matrix4.identity()..translate(0.0, -8.0))
                : Matrix4.identity(),
            child: CustomPaint(
              size: Size(widget.width, widget.height),
              painter: TubePainter(
                segments: widget.tube.segments,
                isSelected: widget.isSelected,
                wavePhase: _waveCtrl.value * 2 * pi,
              ),
            ),
          );
        },
      ),
    );
  }
}
