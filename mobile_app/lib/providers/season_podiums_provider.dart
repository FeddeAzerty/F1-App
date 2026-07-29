import 'package:flutter/foundation.dart';

import '../models/race_detail.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class SeasonPodiumsProvider extends ChangeNotifier {
  SeasonPodiumsProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  String? errorMessage;
  List<RaceDetail> _podiums = [];

  List<RaceDetail> get podiums => List.unmodifiable(_podiums);

  RaceDetail? podiumForRound(int round) {
    for (final p in _podiums) {
      if (p.race.round == round) return p;
    }
    return null;
  }

  Future<void> loadSeason(int season) async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      _podiums = await _apiClient.fetchSeasonPodiums(season);
      status = LoadStatus.loaded;
    } on ApiException catch (e) {
      status = LoadStatus.error;
      errorMessage = e.message;
    }
    notifyListeners();
  }
}
