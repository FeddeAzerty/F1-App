import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_article.dart';
import '../providers/load_status.dart';
import '../providers/news_provider.dart';
import '../utils/date_format.dart';
import '../utils/theme_ext.dart';
import '../widgets/error_state.dart';
import '../widgets/skeleton.dart';
import '../widgets/theme_toggle_button.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.apiClientProvider});

  /// Test hook: supply a pre-configured provider.
  final NewsProvider? apiClientProvider;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsProvider _provider = widget.apiClientProvider ?? NewsProvider();

  @override
  void initState() {
    super.initState();
    if (_provider.status == LoadStatus.initial) _provider.load();
  }

  @override
  void dispose() {
    if (widget.apiClientProvider == null) _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('News'),
          actions: const [ThemeToggleButton()],
        ),
        body: Consumer<NewsProvider>(
          builder: (context, provider, _) {
            switch (provider.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const SkeletonList();
              case LoadStatus.error:
                return ErrorState(onRetry: provider.load);
              case LoadStatus.loaded:
                if (provider.articles.isEmpty) {
                  return const Center(child: Text('No news right now.'));
                }
                return RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.articles.length,
                    itemBuilder: (context, i) =>
                        _NewsCard(article: provider.articles[i]),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});

  final NewsArticle article;

  Future<void> _open() async {
    if (article.url == null) return;
    await launchUrl(Uri.parse(article.url!), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final meta = [
      article.source,
      if (article.publishedAt != null) shortDateTime(article.publishedAt!.toUtc()),
    ].whereType<String>().join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: article.url == null ? null : _open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
