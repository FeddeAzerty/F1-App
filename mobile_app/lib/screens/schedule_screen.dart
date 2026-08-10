import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/race.dart';
import '../providers/load_status.dart';
import '../providers/race_provider.dart';
import '../providers/season_podiums_provider.dart';
import '../widgets/error_state.dart';
import '../widgets/race_grid_card.dart';
import '../widgets/results_table.dart';
import '../widgets/skeleton.dart';
import '../widgets/theme_toggle_button.dart';
import 'race_detail_screen.dart';

enum _ScheduleView { cards, table }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {

  final _raceProvider = RaceProvider();
  final _podiumsProvider = SeasonPodiumsProvider();

  final int _earliestSeason = 1950;
  final int _latestSeason = DateTime.now().year;
  late int _season = DateTime.now().year;
  _ScheduleView _view = _ScheduleView.cards;

  @override
  void initState() {
    super.initState();
    _loadSeason();
  }

  void _loadSeason() {
    _raceProvider.loadSeason(_season);
    _podiumsProvider.loadSeason(_season);
  }

  @override
  void dispose() {
    _raceProvider.dispose();
    _podiumsProvider.dispose();
    super.dispose();
  }

  void _changeSeason(int delta) {
    final next = _season + delta;
    if (next < _earliestSeason || next > _latestSeason) return;
    setState(() => _season = next);
    _loadSeason();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _raceProvider),
        ChangeNotifierProvider.value(value: _podiumsProvider),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          actions: const [ThemeToggleButton()],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _season > _earliestSeason
                            ? () => _changeSeason(-1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '$_season',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: _season < _latestSeason
                            ? () => _changeSeason(1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),

                  SegmentedButton<_ScheduleView>(
                    segments: const [
                      ButtonSegment(
                        value: _ScheduleView.cards,
                        icon: Icon(Icons.grid_view),
                        label: Text('Schedule'),
                      ),
                      ButtonSegment(
                        value: _ScheduleView.table,
                        icon: Icon(Icons.table_rows_outlined),
                        label: Text('Results'),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (selection) =>
                        setState(() => _view = selection.first),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Consumer2<RaceProvider, SeasonPodiumsProvider>(
                builder: (context, raceProvider, podiumsProvider, _) => _Body(
                  view: _view,
                  raceProvider: raceProvider,
                  podiumsProvider: podiumsProvider,
                  onRetry: _loadSeason,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.view,
    required this.raceProvider,
    required this.podiumsProvider,
    required this.onRetry,
  });

  final _ScheduleView view;
  final RaceProvider raceProvider;
  final SeasonPodiumsProvider podiumsProvider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (raceProvider.status == LoadStatus.initial ||
        raceProvider.status == LoadStatus.loading) {
      return view == _ScheduleView.table
          ? const SkeletonList()
          : const SkeletonCardGrid();
    }
    if (raceProvider.status == LoadStatus.error) {
      return ErrorState(onRetry: onRetry);
    }

    final races = raceProvider.races;
    if (races.isEmpty) {
      return const Center(child: Text('No races found for this season.'));
    }

    if (view == _ScheduleView.table) {
      if (podiumsProvider.status == LoadStatus.initial ||
          podiumsProvider.status == LoadStatus.loading) {
        return const SkeletonList();
      }
      if (podiumsProvider.status == LoadStatus.error) {
        return ErrorState(onRetry: onRetry);
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ResultsTable(
          races: podiumsProvider.podiums,
          onRaceTap: (detail) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RaceDetailScreen(
                season: detail.race.season,
                round: detail.race.round,
                raceNameFallback: detail.race.raceName,
              ),
            ),
          ),
        ),
      );
    }

    final nextRace = races
        .where((r) => r.isUpcoming)
        .fold<Race?>(null, (a, b) => a == null || b.round < a.round ? b : a);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 210,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: races.length,
      itemBuilder: (context, index) {
        final race = races[index];
        final podiumDetail = podiumsProvider.podiumForRound(race.round);
        return RaceGridCard(
          race: race,
          podium: podiumDetail?.results,
          isNext: nextRace != null && race.round == nextRace.round,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RaceDetailScreen(
                season: race.season,
                round: race.round,
                raceNameFallback: race.raceName,
              ),
            ),
          ),
        );
      },
    );
  }
}
