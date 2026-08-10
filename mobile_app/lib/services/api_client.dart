import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;

import '../models/circuit_history.dart';
import '../models/detail.dart';
import '../models/news_article.dart';
import '../models/progression.dart';
import '../models/race.dart';
import '../models/race_detail.dart';
import '../models/standings.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

String resolveApiBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? resolveApiBaseUrl();

  final http.Client _client;
  final String baseUrl;

  Future<List<Race>> fetchSeasonSchedule(int season) async {
    final data = await _getJson('/api/races/$season') as List<dynamic>;
    return data
        .map((json) => Race.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<RaceDetail> fetchRaceDetail(int season, int round) async {
    final data = await _getJson('/api/races/$season/$round');
    return RaceDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<RaceDetail>> fetchSeasonPodiums(int season) async {
    final data = await _getJson('/api/races/$season/podiums') as List<dynamic>;
    return data
        .map((json) => RaceDetail.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CircuitHistory> fetchCircuitHistory(String circuitRef) async {
    final data = await _getJson(
      '/api/circuits/$circuitRef/history',
      timeout: const Duration(seconds: 30),
    );
    return CircuitHistory.fromJson(data as Map<String, dynamic>);
  }

  Future<List<DriverStanding>> fetchDriverStandings(int season) async {
    final data =
        await _getJson('/api/standings/drivers/$season') as List<dynamic>;
    return data
        .map((json) => DriverStanding.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConstructorStanding>> fetchConstructorStandings(int season) async {
    final data =
        await _getJson('/api/standings/constructors/$season') as List<dynamic>;
    return data
        .map((json) => ConstructorStanding.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<StandingsProgression> fetchStandingsProgression(int season) async {
    final data = await _getJson('/api/standings/progression/$season');
    return StandingsProgression.fromJson(data as Map<String, dynamic>);
  }

  Future<DriverDetail> fetchDriverDetail(String driverRef) async {
    final data = await _getJson(
      '/api/drivers/$driverRef',
      timeout: const Duration(seconds: 20),
    );
    return DriverDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<ConstructorDetail> fetchConstructorDetail(String constructorRef) async {
    final data = await _getJson(
      '/api/constructors/$constructorRef',
      timeout: const Duration(seconds: 20),
    );
    return ConstructorDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<NewsArticle>> fetchNews() async {
    final data = await _getJson('/api/news') as List<dynamic>;
    return data
        .map((json) => NewsArticle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _getJson(
    String path, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } catch (e) {
      throw ApiException('Could not reach the API at $baseUrl ($e)');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Request to $uri failed with status ${response.statusCode}',
      );
    }

    return jsonDecode(response.body);
  }
}
