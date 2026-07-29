import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/progression.dart';
import '../utils/chart_palette.dart';
import '../utils/theme_ext.dart';

/// Season championship progression: cumulative points per round for the
/// leading drivers. A line chart (change-over-time), one line per driver in
/// fixed categorical-colour order, capped at [maxChartSeries] for legibility
/// and to stay inside the validated palette range. A legend names each line
/// so identity never rests on colour alone.
class StandingsChart extends StatelessWidget {
  const StandingsChart({super.key, required this.progression});

  final StandingsProgression progression;

  @override
  Widget build(BuildContext context) {
    if (progression.rounds.isEmpty || progression.drivers.isEmpty) {
      return const Center(child: Text('No progression data for this season.'));
    }

    final drivers = progression.drivers.take(maxChartSeries).toList();
    final rounds = progression.rounds;
    final maxPoints = drivers
        .expand((d) => d.cumulativePoints)
        .fold<double>(0, (m, p) => p > m ? p : m);
    final gridColor = Theme.of(context).colorScheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: LineChart(
            LineChartData(
              minX: rounds.first.toDouble(),
              maxX: rounds.last.toDouble(),
              minY: 0,
              maxY: (maxPoints * 1.05).ceilToDouble(),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: gridColor, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10, color: context.mutedColor),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Round',
                    style: TextStyle(fontSize: 11, color: context.mutedColor),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: _roundInterval(rounds.length),
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10, color: context.mutedColor),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                for (var i = 0; i < drivers.length; i++)
                  LineChartBarData(
                    spots: [
                      for (var r = 0; r < rounds.length; r++)
                        FlSpot(
                          rounds[r].toDouble(),
                          drivers[i].cumulativePoints[r],
                        ),
                    ],
                    isCurved: false,
                    color: seriesColor(context, i),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (var i = 0; i < drivers.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 3,
                    color: seriesColor(context, i),
                  ),
                  const SizedBox(width: 6),
                  Text(drivers[i].name, style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  double _roundInterval(int count) => count <= 12 ? 2 : 4;
}
