import 'package:flutter/material.dart';

import '../models/race_detail.dart';
import '../utils/constructor_colors.dart';
import '../utils/country_flags.dart';
import '../utils/date_format.dart';
import 'driver_avatar.dart';

/// F1.com-style results table: one row per race, showing the winner.
/// Expects each [RaceDetail.results] to be a podium (sorted by position) -
/// `results.first` is treated as the winner.
class ResultsTable extends StatelessWidget {
  const ResultsTable({super.key, required this.races, this.onRaceTap});

  final List<RaceDetail> races;
  final void Function(RaceDetail detail)? onRaceTap;

  @override
  Widget build(BuildContext context) {
    // Require the race to have actually run, not just to have result data -
    // the data source carries projected results for future races (see
    // RaceGridCard), which shouldn't appear as completed results here.
    final rows = races.where((r) => r.results.isNotEmpty && r.race.isPast).toList()
      ..sort((a, b) => a.race.round.compareTo(b.race.round));

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('No results yet for this season.')),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Grand Prix')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Winner')),
          DataColumn(label: Text('Team')),
          DataColumn(label: Text('Laps')),
          DataColumn(label: Text('Time')),
        ],
        rows: [for (final detail in rows) _buildRow(detail)],
      ),
    );
  }

  DataRow _buildRow(RaceDetail detail) {
    final winner = detail.results.first;
    final circuit = detail.race.circuit;

    return DataRow(
      onSelectChanged: onRaceTap == null ? null : (_) => onRaceTap!(detail),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(countryFlag(circuit.country)),
              const SizedBox(width: 8),
              Text(circuit.country ?? detail.race.raceName),
            ],
          ),
        ),
        DataCell(Text(shortDate(detail.race.raceDate))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DriverAvatar(
                driverRef: winner.driver.driverRef,
                photoUrl: winner.driver.resolvedPhotoUrl,
                radius: 12,
              ),
              const SizedBox(width: 8),
              Text(winner.driver.fullName),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: constructorColor(winner.constructor.constructorRef),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(winner.constructor.name),
            ],
          ),
        ),
        DataCell(Text(winner.laps?.toString() ?? '—')),
        DataCell(Text(winner.finishTime ?? '—')),
      ],
    );
  }
}
