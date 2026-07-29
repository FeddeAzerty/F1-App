import 'package:flutter/foundation.dart';

import '../models/progression.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class ProgressionProvider extends ChangeNotifier {
  ProgressionProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  StandingsProgression? progression;

  Future<void> load(int season) async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      progression = await _apiClient.fetchStandingsProgression(season);
      status = LoadStatus.loaded;
    } on ApiException {
      status = LoadStatus.error;
    }
    notifyListeners();
  }
}
