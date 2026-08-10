import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/load_status.dart';
import '../providers/progression_provider.dart';
import '../providers/standings_provider.dart';
import '../services/api_client.dart';
import '../utils/constructor_colors.dart';
import '../utils/theme_ext.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/error_state.dart';
import '../widgets/skeleton.dart';
import '../widgets/standings_chart.dart';
import '../widgets/theme_toggle_button.dart';
import 'constructor_detail_screen.dart';
import 'driver_detail_screen.dart';

enum _StandingsTab { drivers, constructors, chart }

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late final _provider = StandingsProvider(apiClient: widget.apiClient);
  late final _progression = ProgressionProvider(apiClient: widget.apiClient);

  final int _earliestSeason = 1950;
  final int _latestSeason = DateTime.now().year;
  late int _season = DateTime.now().year;
  _StandingsTab _tab = _StandingsTab.drivers;

  @override
  void initState() {
    super.initState();
    _provider.loadSeason(_season);
  }

  @override
  void dispose() {
    _provider.dispose();
    _progression.dispose();
    super.dispose();
  }

  void _changeSeason(int delta) {
    final next = _season + delta;
    if (next < _earliestSeason || next > _latestSeason) return;
    setState(() => _season = next);
    _provider.loadSeason(_season);
    if (_tab == _StandingsTab.chart) _progression.load(_season);
  }

  void _selectTab(_StandingsTab tab) {
    setState(() => _tab = tab);

    if (tab == _StandingsTab.chart &&
        _progression.status == LoadStatus.initial) {
      _progression.load(_season);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _provider),
        ChangeNotifierProvider.value(value: _progression),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Standings'),
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
                  SegmentedButton<_StandingsTab>(
                    segments: const [
                      ButtonSegment(
                        value: _StandingsTab.drivers,
                        icon: Icon(Icons.person_outline),
                        label: Text('Drivers'),
                      ),
                      ButtonSegment(
                        value: _StandingsTab.constructors,
                        icon: Icon(Icons.groups_outlined),
                        label: Text('Teams'),
                      ),
                      ButtonSegment(
                        value: _StandingsTab.chart,
                        icon: Icon(Icons.show_chart),
                        label: Text('Chart'),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        _selectTab(selection.first),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _tab == _StandingsTab.chart
                  ? Consumer<ProgressionProvider>(
                      builder: (context, prov, _) =>
                          _ChartBody(provider: prov, onRetry: _loadChartRetry),
                    )
                  : Consumer<StandingsProvider>(
                      builder: (context, provider, _) => _Body(
                        provider: provider,
                        tab: _tab,
                        onRetry: _loadRetry,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadRetry() => _provider.loadSeason(_season);
  void _loadChartRetry() => _progression.load(_season);
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({required this.provider, required this.onRetry});

  final ProgressionProvider provider;
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: StandingsChart(progression: provider.progression!),
            ),
          ),
        );
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.tab,
    required this.onRetry,
  });

  final StandingsProvider provider;
  final _StandingsTab tab;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const SkeletonList();
      case LoadStatus.error:
        return ErrorState(onRetry: onRetry);
      case LoadStatus.loaded:
        return tab == _StandingsTab.drivers
            ? _DriverStandings(provider: provider)
            : _ConstructorStandings(provider: provider);
    }
  }
}

class _DriverStandings extends StatelessWidget {
  const _DriverStandings({required this.provider});

  final StandingsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.drivers.isEmpty) {
      return const Center(child: Text('No driver standings for this season.'));
    }
    return ListView.separated(
      itemCount: provider.drivers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = provider.drivers[index];
        return ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DriverDetailScreen(
                driverRef: s.driver.driverRef,
                nameFallback: s.driver.fullName,
              ),
            ),
          ),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 40,
                color: s.constructor == null
                    ? Colors.transparent
                    : constructorColor(s.constructor!.constructorRef),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 20,
                child: Text(
                  s.positionText ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DriverAvatar(
                driverRef: s.driver.driverRef,
                photoUrl: s.driver.resolvedPhotoUrl,
                radius: 14,
              ),
            ],
          ),
          title: Text(s.driver.fullName),
          subtitle: s.constructor == null
              ? null
              : Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.constructor!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.points.toStringAsFixed(0)} pts',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (s.wins > 0)
                Text(
                  '${s.wins} ${s.wins == 1 ? 'win' : 'wins'}',
                  style: TextStyle(fontSize: 11, color: context.mutedColor),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ConstructorStandings extends StatelessWidget {
  const _ConstructorStandings({required this.provider});

  final StandingsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.constructors.isEmpty) {
      return const Center(
        child: Text('No constructor standings for this season.'),
      );
    }
    return ListView.separated(
      itemCount: provider.constructors.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = provider.constructors[index];
        return ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConstructorDetailScreen(
                constructorRef: s.constructor.constructorRef,
                nameFallback: s.constructor.name,
              ),
            ),
          ),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 40,
                color: constructorColor(s.constructor.constructorRef),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 20,
                child: Text(
                  s.positionText ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          title: Text(s.constructor.name),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.points.toStringAsFixed(0)} pts',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (s.wins > 0)
                Text(
                  '${s.wins} ${s.wins == 1 ? 'win' : 'wins'}',
                  style: TextStyle(fontSize: 11, color: context.mutedColor),
                ),
            ],
          ),
        );
      },
    );
  }
}
