import 'package:flutter/foundation.dart';

import '../models/detail.dart';
import '../services/api_client.dart';
import 'load_status.dart';

class DriverDetailProvider extends ChangeNotifier {
  DriverDetailProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  DriverDetail? detail;

  Future<void> load(String driverRef) async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      detail = await _apiClient.fetchDriverDetail(driverRef);
      status = LoadStatus.loaded;
    } on ApiException {
      status = LoadStatus.error;
    }
    notifyListeners();
  }
}

class ConstructorDetailProvider extends ChangeNotifier {
  ConstructorDetailProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  LoadStatus status = LoadStatus.initial;
  ConstructorDetail? detail;

  Future<void> load(String constructorRef) async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      detail = await _apiClient.fetchConstructorDetail(constructorRef);
      status = LoadStatus.loaded;
    } on ApiException {
      status = LoadStatus.error;
    }
    notifyListeners();
  }
}
