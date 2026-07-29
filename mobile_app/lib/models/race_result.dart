import 'constructor.dart';
import 'driver.dart';

class RaceResult {
  const RaceResult({
    required this.points,
    required this.driver,
    required this.constructor,
    this.position,
    this.positionText,
    this.grid,
    this.laps,
    this.status,
    this.finishTimeMillis,
    this.finishTime,
    this.fastestLapRank,
    this.fastestLapNumber,
    this.fastestLapTime,
    this.fastestLapSpeedKph,
  });

  final int? position;
  final String? positionText;
  final double points;
  final int? grid;
  final int? laps;
  final String? status;
  final Driver driver;
  final Constructor constructor;

  /// Full elapsed race time for the winner (e.g. "1:33:56.820"), or the gap
  /// to the leader for other classified finishers (e.g. "+2.974"). Null for
  /// retirements/DNFs.
  final int? finishTimeMillis;
  final String? finishTime;

  /// `fastestLapRank == 1` means this driver set the fastest lap of the race.
  final int? fastestLapRank;
  final int? fastestLapNumber;
  final String? fastestLapTime;
  final double? fastestLapSpeedKph;

  bool get isRaceWinner => position == 1;
  bool get setFastestLap => fastestLapRank == 1;

  factory RaceResult.fromJson(Map<String, dynamic> json) {
    return RaceResult(
      position: json['position'] as int?,
      positionText: json['position_text'] as String?,
      points: (json['points'] as num).toDouble(),
      grid: json['grid'] as int?,
      laps: json['laps'] as int?,
      status: json['status'] as String?,
      driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
      constructor: Constructor.fromJson(
        json['constructor'] as Map<String, dynamic>,
      ),
      finishTimeMillis: json['finish_time_millis'] as int?,
      finishTime: json['finish_time'] as String?,
      fastestLapRank: json['fastest_lap_rank'] as int?,
      fastestLapNumber: json['fastest_lap_number'] as int?,
      fastestLapTime: json['fastest_lap_time'] as String?,
      fastestLapSpeedKph: (json['fastest_lap_speed_kph'] as num?)?.toDouble(),
    );
  }
}
