import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/race_result.dart';
import '../providers/circuit_history_provider.dart';
import '../providers/load_status.dart';
import '../providers/race_detail_provider.dart';
import '../services/api_client.dart';
import '../utils/theme_ext.dart';
import '../widgets/circuit_history_card.dart';
import '../widgets/circuit_map.dart';
import '../widgets/circuit_track_diagram.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/error_state.dart';
import '../widgets/race_result_tile.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/weekend_schedule.dart';
import 'driver_detail_screen.dart';

class RaceDetailScreen extends StatelessWidget {
  const RaceDetailScreen({
    super.key,
    required this.season,
    required this.round,
    required this.raceNameFallback,
    this.apiClient,
  });

  final int season;
  final int round;

  /// Shown in the AppBar immediately, before the detail request resolves -
  /// avoids a blank title while loading since we already know it from the
  /// race list that got us here.
  final String raceNameFallback;

  /// Overridable for tests; defaults to the real backend client.
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          RaceDetailProvider(apiClient: apiClient)..load(season, round),
      child: Scaffold(
        appBar: AppBar(
          title: Text(raceNameFallback),
          actions: const [ThemeToggleButton()],
        ),
        body: Consumer<RaceDetailProvider>(
          builder: (context, provider, _) => _Body(
            provider: provider,
            onRetry: () => provider.load(season, round),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.onRetry});

  final RaceDetailProvider provider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case LoadStatus.error:
        return ErrorState(onRetry: onRetry);

      case LoadStatus.loaded:
        final detail = provider.detail!;
        final circuit = detail.race.circuit;
        // Treat a future race as having no results even if the data source
        // supplied projected ones (see RaceGridCard) - so upcoming races
        // show the "At this circuit" history instead of a fake result.
        final hasRun = detail.race.isPast && detail.results.isNotEmpty;
        final winner = hasRun
            ? detail.results.firstWhere(
                (r) => r.isRaceWinner,
                orElse: () => detail.results.first,
              )
            : null;

        final hasDiagram = CircuitTrackDiagram.hasDiagram(circuit.circuitRef);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The track outline stays the prominent top visual when
                  // available; the live map moves down into the info row
                  // below instead of being replaced. Circuits without a
                  // track diagram use the live map as the top visual
                  // instead, since showing it twice would be redundant.
                  if (hasDiagram)
                    CircuitTrackDiagram(circuitRef: circuit.circuitRef)
                  else
                    CircuitMap(circuit: circuit),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDiagram) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 170,
                              height: 170,
                              child: CircuitMap(circuit: circuit),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                circuit.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (circuit.locality != null)
                                Text(
                                  '${circuit.locality}, ${circuit.country}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (winner?.laps != null) ...[
                                const SizedBox(height: 8),
                                _StatChip(
                                  icon: Icons.flag_outlined,
                                  label: '${winner!.laps} laps',
                                ),
                              ],
                              const SizedBox(height: 10),
                              WeekendSchedule(race: detail.race),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasRun) ...[
              const SizedBox(height: 20),
              _WinnerBanner(results: detail.results),
              const SizedBox(height: 24),
              Text('Results', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              ...detail.results.map(
                (r) => RaceResultTile(
                  result: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DriverDetailScreen(
                        driverRef: r.driver.driverRef,
                        nameFallback: r.driver.fullName,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Upcoming race - no results of its own yet, so show what's
              // happened at this circuit before instead of an empty page.
              const SizedBox(height: 24),
              Text(
                'At this circuit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _CircuitHistorySection(circuitRef: circuit.circuitRef),
            ],
          ],
        );
    }
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.results});

  final List<RaceResult> results;

  @override
  Widget build(BuildContext context) {
    RaceResult? winner;
    RaceResult? fastestLap;
    for (final r in results) {
      if (r.isRaceWinner) winner = r;
      if (r.setFastestLap) fastestLap = r;
    }
    if (winner == null) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DriverAvatar(
                  driverRef: winner.driver.driverRef,
                  photoUrl: winner.driver.resolvedPhotoUrl,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Winner',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.mutedColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        winner.driver.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        winner.constructor.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (winner.finishTime != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        // Full race duration (H:MM:SS), not a single lap -
                        // easy to mistake for one next to the much smaller
                        // fastest-lap time below without this label.
                        'RACE TIME',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.mutedColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        winner.finishTime!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
              ],
            ),
            if (fastestLap != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.bolt, size: 18, color: Colors.purple.shade300),
                  const SizedBox(width: 6),
                  Text(
                    'Fastest lap: ${fastestLap.driver.fullName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (fastestLap.fastestLapTime != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'LAP TIME',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.mutedColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          fastestLap.fastestLapTime!,
                          style: TextStyle(
                            color: Colors.purple.shade300,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loads and shows circuit history for an upcoming race. Owns its own
/// provider so the (potentially slow, cold-cache) history fetch only fires
/// when a race actually has no results, not on every race-detail open.
class _CircuitHistorySection extends StatelessWidget {
  const _CircuitHistorySection({required this.circuitRef});

  final String circuitRef;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CircuitHistoryProvider()..load(circuitRef),
      child: Consumer<CircuitHistoryProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            case LoadStatus.error:
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Circuit history unavailable.')),
              );
            case LoadStatus.loaded:
              return CircuitHistoryCard(history: provider.history!);
          }
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
