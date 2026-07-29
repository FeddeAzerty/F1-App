import 'package:flutter/foundation.dart';

import '../models/race_detail.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class RaceDetailProvider extends ChangeNotifier {
  RaceDetailProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  String? errorMessage;
  RaceDetail? detail;

  Future<void> load(int season, int round) async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      detail = await _apiClient.fetchRaceDetail(season, round);
      status = LoadStatus.loaded;
    } on ApiException catch (e) {
      status = LoadStatus.error;
      errorMessage = e.message;
    }
    notifyListeners();
  }
}
