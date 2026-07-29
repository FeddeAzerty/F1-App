import 'constructor.dart';
import 'driver.dart';

/// Last winner + recent fastest lap at a circuit (see backend
/// CircuitHistoryOut). Shown on upcoming race pages, which have no results
/// of their own yet.
class CircuitHistory {
  const CircuitHistory({
    required this.hasData,
    this.lastRaceSeason,
    this.lastRaceName,
    this.lastWinner,
    this.lastWinnerConstructor,
    this.lapRecordTime,
    this.lapRecordDriver,
    this.lapRecordConstructor,
    this.lapRecordSeason,
  });

  final bool hasData;

  final int? lastRaceSeason;
  final String? lastRaceName;
  final Driver? lastWinner;
  final Constructor? lastWinnerConstructor;

  final String? lapRecordTime;
  final Driver? lapRecordDriver;
  final Constructor? lapRecordConstructor;
  final int? lapRecordSeason;

  static Driver? _driver(dynamic json) =>
      json == null ? null : Driver.fromJson(json as Map<String, dynamic>);

  static Constructor? _constructor(dynamic json) =>
      json == null ? null : Constructor.fromJson(json as Map<String, dynamic>);

  factory CircuitHistory.fromJson(Map<String, dynamic> json) {
    return CircuitHistory(
      hasData: json['has_data'] as bool,
      lastRaceSeason: json['last_race_season'] as int?,
      lastRaceName: json['last_race_name'] as String?,
      lastWinner: _driver(json['last_winner']),
      lastWinnerConstructor: _constructor(json['last_winner_constructor']),
      lapRecordTime: json['lap_record_time'] as String?,
      lapRecordDriver: _driver(json['lap_record_driver']),
      lapRecordConstructor: _constructor(json['lap_record_constructor']),
      lapRecordSeason: json['lap_record_season'] as int?,
    );
  }
}
