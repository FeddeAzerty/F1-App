class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.summary,
    this.url,
    this.imageUrl,
    this.source,
    this.publishedAt,
  });

  final String title;
  final String summary;
  final String? url;
  final String? imageUrl;
  final String? source;
  final DateTime? publishedAt;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String,
      summary: json['summary'] as String? ?? '',
      url: json['url'] as String?,
      imageUrl: json['image_url'] as String?,
      source: json['source'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }
}
