import 'race.dart';
import 'race_result.dart';

class RaceDetail {
  const RaceDetail({required this.race, required this.results});

  final Race race;
  final List<RaceResult> results;

  factory RaceDetail.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>? ?? [];
    return RaceDetail(
      race: Race.fromJson(json),
      results: resultsJson
          .map((r) => RaceResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
