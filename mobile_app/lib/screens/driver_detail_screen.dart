import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/detail.dart';
import '../providers/detail_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/load_status.dart';
import '../services/api_client.dart';
import '../utils/theme_ext.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/error_state.dart';
import '../widgets/stat_tile.dart';

class DriverDetailScreen extends StatelessWidget {
  const DriverDetailScreen({
    super.key,
    required this.driverRef,
    required this.nameFallback,
    this.apiClient,
  });

  final String driverRef;
  final String nameFallback;
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverDetailProvider(apiClient: apiClient)..load(driverRef),
      child: Scaffold(
        appBar: AppBar(
          title: Text(nameFallback),
          actions: [
            Consumer<FavoritesProvider>(
              builder: (context, favs, _) => IconButton(
                icon: Icon(
                  favs.isDriverFavorite(driverRef)
                      ? Icons.star
                      : Icons.star_border,
                  color: favs.isDriverFavorite(driverRef) ? Colors.amber : null,
                ),
                tooltip: 'Favourite',
                onPressed: () => favs.toggleDriver(driverRef),
              ),
            ),
          ],
        ),
        body: Consumer<DriverDetailProvider>(
          builder: (context, provider, _) {
            switch (provider.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LoadStatus.error:
                return ErrorState(onRetry: () => provider.load(driverRef));
              case LoadStatus.loaded:
                return _Body(detail: provider.detail!);
            }
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final DriverDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail.driver;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            DriverAvatar(
              driverRef: d.driverRef,
              photoUrl: d.resolvedPhotoUrl,
              radius: 44,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.fullName, style: Theme.of(context).textTheme.titleLarge),
                  if (d.nationality != null)
                    Text(
                      d.nationality!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
                    ),
                  if (d.permanentNumber != null || d.code != null)
                    Text(
                      [
                        if (d.permanentNumber != null) '#${d.permanentNumber}',
                        if (d.code != null) d.code,
                      ].join('  ·  '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: StatTile(label: 'Race entries', value: '${detail.careerEntries}'),
            ),
            const SizedBox(width: 12),
            Expanded(child: StatTile(label: 'Wins', value: '${detail.careerWins}')),
          ],
        ),
        const SizedBox(height: 24),
        Text('Recent results', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (detail.recentResults.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No recent results.'),
          )
        else
          ...detail.recentResults.map((r) => _ResultRow(result: r)),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final ResultSummary result;

  @override
  Widget build(BuildContext context) {
    final isPodium = result.position != null && result.position! <= 3;
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 28,
        child: Text(
          result.positionText ?? '—',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPodium ? Colors.amber.shade600 : null,
          ),
        ),
      ),
      title: Text('${result.season} ${result.raceName}'),
      trailing: Text('${result.points.toStringAsFixed(0)} pts'),
    );
  }
}
