import 'package:flutter/material.dart';

import '../models/race.dart';
import '../utils/date_format.dart';

class WeekendSchedule extends StatelessWidget {
  const WeekendSchedule({super.key, required this.race});

  final Race race;

  @override
  Widget build(BuildContext context) {
    final sessions = <(String, DateTime?)>[
      ('Practice 1', race.firstPracticeAt),
      if (!race.isSprintWeekend) ('Practice 2', race.secondPracticeAt),
      if (!race.isSprintWeekend) ('Practice 3', race.thirdPracticeAt),
      if (race.isSprintWeekend) ('Sprint Qualifying', race.sprintQualifyingAt),
      if (race.isSprintWeekend) ('Sprint', race.sprintAt),
      ('Qualifying', race.qualifyingAt),
      ('Race', race.startAtUtc),
    ].where((s) => s.$2 != null).toList();

    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, time) in sessions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  shortDateTime(time!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
