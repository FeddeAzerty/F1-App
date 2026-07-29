import 'constructor.dart';
import 'driver.dart';

class DriverStanding {
  const DriverStanding({
    required this.points,
    required this.wins,
    required this.driver,
    this.position,
    this.positionText,
    this.constructor,
  });

  final int? position;
  final String? positionText;
  final double points;
  final int wins;
  final Driver driver;
  final Constructor? constructor;

  factory DriverStanding.fromJson(Map<String, dynamic> json) {
    return DriverStanding(
      position: json['position'] as int?,
      positionText: json['position_text'] as String?,
      points: (json['points'] as num).toDouble(),
      wins: json['wins'] as int,
      driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
      constructor: json['constructor'] == null
          ? null
          : Constructor.fromJson(json['constructor'] as Map<String, dynamic>),
    );
  }
}

class ConstructorStanding {
  const ConstructorStanding({
    required this.points,
    required this.wins,
    required this.constructor,
    this.position,
    this.positionText,
  });

  final int? position;
  final String? positionText;
  final double points;
  final int wins;
  final Constructor constructor;

  factory ConstructorStanding.fromJson(Map<String, dynamic> json) {
    return ConstructorStanding(
      position: json['position'] as int?,
      positionText: json['position_text'] as String?,
      points: (json['points'] as num).toDouble(),
      wins: json['wins'] as int,
      constructor: Constructor.fromJson(
        json['constructor'] as Map<String, dynamic>,
      ),
    );
  }
}
