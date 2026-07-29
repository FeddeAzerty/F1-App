import 'package:flutter/foundation.dart';

import '../models/standings.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class StandingsProvider extends ChangeNotifier {
  StandingsProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  String? errorMessage;
  List<DriverStanding> drivers = [];
  List<ConstructorStanding> constructors = [];

  Future<void> loadSeason(int season) async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiClient.fetchDriverStandings(season),
        _apiClient.fetchConstructorStandings(season),
      ]);
      drivers = results[0] as List<DriverStanding>;
      constructors = results[1] as List<ConstructorStanding>;
      status = LoadStatus.loaded;
    } on ApiException catch (e) {
      status = LoadStatus.error;
      errorMessage = e.message;
    }
    notifyListeners();
  }
}
