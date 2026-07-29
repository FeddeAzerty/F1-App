import 'package:flutter/foundation.dart';

import '../models/circuit_history.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class CircuitHistoryProvider extends ChangeNotifier {
  CircuitHistoryProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  CircuitHistory? history;

  Future<void> load(String circuitRef) async {
    status = LoadStatus.loading;
    notifyListeners();

    try {
      history = await _apiClient.fetchCircuitHistory(circuitRef);
      status = LoadStatus.loaded;
    } on ApiException {
      // Circuit history is supplementary - if it fails, the race detail
      // page still shows everything else, so this stays quiet rather than
      // surfacing an error state of its own.
      status = LoadStatus.error;
    }
    notifyListeners();
  }
}
