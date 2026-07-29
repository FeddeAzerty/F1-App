import 'package:flutter/material.dart';

import '../models/race.dart';
import '../utils/theme_ext.dart';

class RaceListTile extends StatelessWidget {
  const RaceListTile({super.key, required this.race, this.onTap});

  final Race race;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = race.raceDate;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final locationLabel = race.circuit.locality != null
        ? '${race.circuit.name} — ${race.circuit.locality}, ${race.circuit.country}'
        : race.circuit.name;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: race.isPast
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          child: Text('${race.round}'),
        ),
        title: Text(race.raceName),
        subtitle: Text(locationLabel),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(dateLabel),
            Text(
              race.isPast ? 'Completed' : 'Upcoming',
              style: TextStyle(
                fontSize: 11,
                color: race.isPast
                    ? context.mutedColor
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
