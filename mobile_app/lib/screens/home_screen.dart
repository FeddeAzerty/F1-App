import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/race.dart';
import '../providers/favorites_provider.dart';
import '../providers/load_status.dart';
import '../providers/race_provider.dart';
import '../widgets/error_state.dart';
import '../widgets/next_race_countdown.dart';
import '../widgets/race_list_tile.dart';
import '../widgets/skeleton.dart';
import '../widgets/theme_toggle_button.dart';
import 'driver_detail_screen.dart';
import 'race_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RaceProvider>().loadSeason(DateTime.now().year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final raceProvider = context.watch<RaceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Portfolio'),
        actions: const [ThemeToggleButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<RaceProvider>().loadSeason(DateTime.now().year),
        child: _Body(provider: raceProvider),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider});

  final RaceProvider provider;

  void _openRace(BuildContext context, Race race) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RaceDetailScreen(
          season: race.season,
          round: race.round,
          raceNameFallback: race.raceName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const SkeletonList();

      case LoadStatus.error:
        return ListView(
          children: [
            const SizedBox(height: 48),
            ErrorState(
              onRetry: () =>
                  context.read<RaceProvider>().loadSeason(DateTime.now().year),
            ),
          ],
        );

      case LoadStatus.loaded:
        final races = provider.upcomingRaces;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (races.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: NextRaceCountdown(
                  race: races.first,
                  onTap: () => _openRace(context, races.first),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const _FavoritesStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                races.isEmpty ? 'Season complete' : 'Upcoming races',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (races.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No more races scheduled this season.'),
                ),
              )
            else
              ...races.map(
                (race) => RaceListTile(
                  race: race,
                  onTap: () => _openRace(context, race),
                ),
              ),
          ],
        );
    }
  }
}

/// Horizontal strip of the user's favourited drivers, tappable through to
/// their detail pages. Hidden entirely when there are no favourites.
class _FavoritesStrip extends StatelessWidget {
  const _FavoritesStrip();

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favs, _) {
        final refs = favs.driverRefs.toList();
        if (refs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Your drivers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final ref in refs)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                        label: Text(ref.replaceAll('_', ' ')),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DriverDetailScreen(
                              driverRef: ref,
                              nameFallback: ref.replaceAll('_', ' '),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
