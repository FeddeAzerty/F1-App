import 'package:flutter/material.dart';

const _lightSeries = [
  Color(0xFF2A78D6),
  Color(0xFFEB6834),
  Color(0xFF1BAF7A),
  Color(0xFFEDA100),
  Color(0xFFE87BA4),
];

const _darkSeries = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
];

const int maxChartSeries = 5;

Color seriesColor(BuildContext context, int index) {
  final palette = Theme.of(context).brightness == Brightness.dark
      ? _darkSeries
      : _lightSeries;
  return palette[index % palette.length];
}
