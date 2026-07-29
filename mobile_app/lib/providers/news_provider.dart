import 'package:flutter/foundation.dart';

import '../models/news_article.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class NewsProvider extends ChangeNotifier {
  NewsProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  List<NewsArticle> articles = [];

  Future<void> load() async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      articles = await _apiClient.fetchNews();
      status = LoadStatus.loaded;
    } on ApiException {
      status = LoadStatus.error;
    }
    notifyListeners();
  }
}
