import 'package:flutter/material.dart';

import '../models/race.dart';
import '../models/race_result.dart';
import '../utils/country_flags.dart';
import '../utils/date_format.dart';
import '../utils/theme_ext.dart';
import 'driver_avatar.dart';

class RaceGridCard extends StatelessWidget {
  const RaceGridCard({
    super.key,
    required this.race,
    this.podium,
    this.isNext = false,
    this.onTap,
  });

  final Race race;

  final List<RaceResult>? podium;

  final bool isNext;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {

    final showPodium = race.isPast && podium != null && podium!.isNotEmpty;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isNext
          ? RoundedRectangleBorder(
              side: BorderSide(color: primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'ROUND ${race.round}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.8,
                          color: context.mutedColor,
                        ),
                      ),
                      if (isNext) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEXT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    shortDate(race.raceDate),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    countryFlag(race.circuit.country),
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      race.circuit.country ?? race.raceName,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                race.raceName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (showPodium)
                ...podium!.map((r) => _PodiumRow(result: r))
              else
                _UpcomingInfo(race: race),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingInfo extends StatelessWidget {
  const _UpcomingInfo({required this.race});

  final Race race;

  @override
  Widget build(BuildContext context) {
    final sessions = <(String, DateTime?)>[
      ('Qualifying', race.qualifyingAt),
      ('Race', race.raceTime != null ? race.startAtUtc : null),
    ].where((s) => s.$2 != null).toList();

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Upcoming',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, time) in sessions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.mutedColor),
                ),
                Text(
                  shortDateTime(time!),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PodiumRow extends StatelessWidget {
  const _PodiumRow({required this.result});

  final RaceResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              result.positionText ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          DriverAvatar(
            driverRef: result.driver.driverRef,
            photoUrl: result.driver.resolvedPhotoUrl,
            radius: 11,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              result.driver.code ?? result.driver.familyName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            result.finishTime ?? '',
            style: TextStyle(fontSize: 11, color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}
