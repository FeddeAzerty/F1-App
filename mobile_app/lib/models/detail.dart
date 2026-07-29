import 'constructor.dart';
import 'driver.dart';

class ResultSummary {
  const ResultSummary({
    required this.season,
    required this.round,
    required this.raceName,
    required this.points,
    this.position,
    this.positionText,
  });

  final int season;
  final int round;
  final String raceName;
  final int? position;
  final String? positionText;
  final double points;

  factory ResultSummary.fromJson(Map<String, dynamic> json) {
    return ResultSummary(
      season: json['season'] as int,
      round: json['round'] as int,
      raceName: json['race_name'] as String,
      position: json['position'] as int?,
      positionText: json['position_text'] as String?,
      points: (json['points'] as num).toDouble(),
    );
  }
}

class DriverDetail {
  const DriverDetail({
    required this.driver,
    required this.careerEntries,
    required this.careerWins,
    required this.recentResults,
  });

  final Driver driver;
  final int careerEntries;
  final int careerWins;
  final List<ResultSummary> recentResults;

  factory DriverDetail.fromJson(Map<String, dynamic> json) {
    return DriverDetail(
      driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
      careerEntries: json['career_entries'] as int,
      careerWins: json['career_wins'] as int,
      recentResults: (json['recent_results'] as List<dynamic>)
          .map((e) => ResultSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConstructorDetail {
  const ConstructorDetail({
    required this.constructor,
    required this.careerWins,
    required this.recentResults,
  });

  final Constructor constructor;
  final int careerWins;
  final List<ResultSummary> recentResults;

  factory ConstructorDetail.fromJson(Map<String, dynamic> json) {
    return ConstructorDetail(
      constructor: Constructor.fromJson(json['constructor'] as Map<String, dynamic>),
      careerWins: json['career_wins'] as int,
      recentResults: (json['recent_results'] as List<dynamic>)
          .map((e) => ResultSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
