import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Number of columns that fit in [width]: as many as fit at [minItemWidth]
/// (with [spacing] between them), at least 1 and at most [maxColumns].
int adaptiveColumns(
  double width, {
  required double minItemWidth,
  required int maxColumns,
  double spacing = 16,
}) {
  if (!width.isFinite || width <= 0) return 1;
  final fit = ((width + spacing) / (minItemWidth + spacing)).floor();
  return math.max(1, math.min(maxColumns, fit));
}

/// Lays children out in equal-width columns that follow the available width
/// (rows wrap). Unlike GridView it sizes itself to its children, so it can
/// sit inside a scrolling page.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    required this.minItemWidth,
    this.maxColumns = 4,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = adaptiveColumns(
        constraints.maxWidth,
        minItemWidth: minItemWidth,
        maxColumns: maxColumns,
        spacing: spacing,
      );
      final itemWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: itemWidth, child: child),
        ],
      );
    });
  }
}
