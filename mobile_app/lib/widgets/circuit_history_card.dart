import 'package:flutter/material.dart';

import '../models/circuit_history.dart';
import '../utils/theme_ext.dart';
import 'driver_avatar.dart';

/// Shown on upcoming-race pages in place of results that don't exist yet:
/// who won here last time, and the fastest lap among recent races.
class CircuitHistoryCard extends StatelessWidget {
  const CircuitHistoryCard({super.key, required this.history});

  final CircuitHistory history;

  @override
  Widget build(BuildContext context) {
    if (!history.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No past races recorded at this circuit.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.lastWinner != null)
          _HistoryRow(
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.amber.shade600,
            label: history.lastRaceSeason != null
                ? 'Last winner (${history.lastRaceSeason})'
                : 'Last winner',
            driverRef: history.lastWinner!.driverRef,
            photoUrl: history.lastWinner!.resolvedPhotoUrl,
            name: history.lastWinner!.fullName,
            subtitle: history.lastWinnerConstructor?.name,
            trailing: null,
          ),
        if (history.lapRecordDriver != null) ...[
          const SizedBox(height: 8),
          _HistoryRow(
            icon: Icons.bolt,
            iconColor: Colors.purple.shade300,
            label: history.lapRecordSeason != null
                ? 'Fastest lap (${history.lapRecordSeason})'
                : 'Fastest lap',
            driverRef: history.lapRecordDriver!.driverRef,
            photoUrl: history.lapRecordDriver!.resolvedPhotoUrl,
            name: history.lapRecordDriver!.fullName,
            subtitle: history.lapRecordConstructor?.name,
            trailing: history.lapRecordTime,
          ),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.driverRef,
    required this.photoUrl,
    required this.name,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String driverRef;
  final String? photoUrl;
  final String name;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DriverAvatar(driverRef: driverRef, photoUrl: photoUrl, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: 4),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.mutedColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null)
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
