import 'dart:async';

import 'package:flutter/material.dart';

import '../models/race.dart';
import '../utils/country_flags.dart';

/// A live-ticking countdown banner to the next race's start. Ticks once a
/// second via its own timer (stopped on dispose).
class NextRaceCountdown extends StatefulWidget {
  const NextRaceCountdown({super.key, required this.race, this.onTap});

  final Race race;
  final VoidCallback? onTap;

  @override
  State<NextRaceCountdown> createState() => _NextRaceCountdownState();
}

class _NextRaceCountdownState extends State<NextRaceCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _computeRemaining());
    });
  }

  Duration _computeRemaining() {
    final diff = widget.race.startAtUtc.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT RACE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    countryFlag(widget.race.circuit.country),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.race.raceName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TimeCell(value: days, label: 'DAYS', scheme: scheme),
                  _TimeCell(value: hours, label: 'HRS', scheme: scheme),
                  _TimeCell(value: minutes, label: 'MIN', scheme: scheme),
                  _TimeCell(value: seconds, label: 'SEC', scheme: scheme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.value,
    required this.label,
    required this.scheme,
  });

  final int value;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
