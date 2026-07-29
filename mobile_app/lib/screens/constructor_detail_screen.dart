import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/detail.dart';
import '../providers/detail_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/load_status.dart';
import '../services/api_client.dart';
import '../utils/constructor_colors.dart';
import '../utils/theme_ext.dart';
import '../widgets/error_state.dart';
import '../widgets/stat_tile.dart';

class ConstructorDetailScreen extends StatelessWidget {
  const ConstructorDetailScreen({
    super.key,
    required this.constructorRef,
    required this.nameFallback,
    this.apiClient,
  });

  final String constructorRef;
  final String nameFallback;
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ConstructorDetailProvider(apiClient: apiClient)..load(constructorRef),
      child: Scaffold(
        appBar: AppBar(
          title: Text(nameFallback),
          actions: [
            Consumer<FavoritesProvider>(
              builder: (context, favs, _) => IconButton(
                icon: Icon(
                  favs.isConstructorFavorite(constructorRef)
                      ? Icons.star
                      : Icons.star_border,
                  color: favs.isConstructorFavorite(constructorRef)
                      ? Colors.amber
                      : null,
                ),
                tooltip: 'Favourite',
                onPressed: () => favs.toggleConstructor(constructorRef),
              ),
            ),
          ],
        ),
        body: Consumer<ConstructorDetailProvider>(
          builder: (context, provider, _) {
            switch (provider.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LoadStatus.error:
                return ErrorState(onRetry: () => provider.load(constructorRef));
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

  final ConstructorDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = detail.constructor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 48,
              decoration: BoxDecoration(
                color: constructorColor(c.constructorRef),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: Theme.of(context).textTheme.titleLarge),
                  if (c.nationality != null)
                    Text(
                      c.nationality!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StatTile(label: 'Career race wins', value: '${detail.careerWins}'),
        const SizedBox(height: 24),
        Text('Recent results', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (detail.recentResults.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No recent results.'),
          )
        else
          ...detail.recentResults.map(
            (r) => ListTile(
              dense: true,
              leading: SizedBox(
                width: 28,
                child: Text(
                  r.positionText ?? '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (r.position != null && r.position! <= 3)
                        ? Colors.amber.shade600
                        : null,
                  ),
                ),
              ),
              title: Text('${r.season} ${r.raceName}'),
              subtitle: Text('Best car finish'),
              trailing: Text('${r.points.toStringAsFixed(0)} pts'),
            ),
          ),
      ],
    );
  }
}
