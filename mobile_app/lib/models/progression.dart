class DriverProgression {
  const DriverProgression({
    required this.driverRef,
    required this.name,
    required this.cumulativePoints,
  });

  final String driverRef;
  final String name;
  final List<double> cumulativePoints;

  factory DriverProgression.fromJson(Map<String, dynamic> json) {
    return DriverProgression(
      driverRef: json['driver_ref'] as String,
      name: json['name'] as String,
      cumulativePoints: (json['cumulative_points'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class StandingsProgression {
  const StandingsProgression({required this.rounds, required this.drivers});

  final List<int> rounds;
  final List<DriverProgression> drivers;

  factory StandingsProgression.fromJson(Map<String, dynamic> json) {
    return StandingsProgression(
      rounds: (json['rounds'] as List<dynamic>).map((e) => e as int).toList(),
      drivers: (json['drivers'] as List<dynamic>)
          .map((e) => DriverProgression.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
