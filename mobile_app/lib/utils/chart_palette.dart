import 'package:flutter/material.dart';

/// Categorical chart colours (slots 1-5) from the data-viz reference
/// palette, which validated this fixed order as colourblind-safe on the
/// adjacent pairlist (lines) in both modes. Assigned by series index in
/// fixed order - never cycled, never reordered by rank. We cap series at 5
/// so we stay inside the validated range and the chart stays legible.
const _lightSeries = [
  Color(0xFF2A78D6), // blue
  Color(0xFFEB6834), // orange
  Color(0xFF1BAF7A), // aqua
  Color(0xFFEDA100), // yellow
  Color(0xFFE87BA4), // magenta
];

const _darkSeries = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
];

/// Max series the progression chart shows (see palette note above).
const int maxChartSeries = 5;

Color seriesColor(BuildContext context, int index) {
  final palette = Theme.of(context).brightness == Brightness.dark
      ? _darkSeries
      : _lightSeries;
  return palette[index % palette.length];
}
