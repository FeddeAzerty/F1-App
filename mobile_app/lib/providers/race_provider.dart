import 'package:flutter/foundation.dart';

import '../models/race.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class RaceProvider extends ChangeNotifier {
  RaceProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  String? errorMessage;
  List<Race> _races = [];

  List<Race> get upcomingRaces {
    final upcoming = _races.where((race) => race.isUpcoming).toList();
    upcoming.sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
    return upcoming;
  }

  List<Race> get races {
    final all = List<Race>.of(_races);
    all.sort((a, b) => a.round.compareTo(b.round));
    return all;
  }

  Future<void> loadSeason(int season) async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      _races = await _apiClient.fetchSeasonSchedule(season);
      status = LoadStatus.loaded;
    } on ApiException catch (e) {
      status = LoadStatus.error;
      errorMessage = e.message;
    }
    notifyListeners();
  }
}
