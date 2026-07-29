import 'circuit.dart';

/// Parses a backend datetime string (naive, always UTC) as UTC - plain
/// `DateTime.parse` would otherwise interpret a string with no offset/`Z`
/// suffix as local time, silently shifting session times by the device's
/// timezone offset.
DateTime? _parseUtc(dynamic value) {
  if (value == null) return null;
  return DateTime.parse('${value as String}Z');
}

class Race {
  const Race({
    required this.season,
    required this.round,
    required this.raceName,
    required this.raceDate,
    required this.circuit,
    this.raceTime,
    this.url,
    this.firstPracticeAt,
    this.secondPracticeAt,
    this.thirdPracticeAt,
    this.qualifyingAt,
    this.sprintAt,
    this.sprintQualifyingAt,
  });

  final int season;
  final int round;
  final String raceName;
  final DateTime raceDate;

  /// Race start time as returned by the API, "HH:MM:SS" in UTC. Kept as a
  /// raw string and only parsed when combined with [raceDate] below - the
  /// API omits it for races without a confirmed start time.
  final String? raceTime;
  final String? url;
  final Circuit circuit;

  // Weekend session schedule, all UTC. Sprint/SprintQualifying are only
  // set on sprint weekends; all are null until a schedule sync has run for
  // this race (see backend's sync_season_schedule vs sync_race).
  final DateTime? firstPracticeAt;
  final DateTime? secondPracticeAt;
  final DateTime? thirdPracticeAt;
  final DateTime? qualifyingAt;
  final DateTime? sprintAt;
  final DateTime? sprintQualifyingAt;

  bool get isSprintWeekend => sprintAt != null;

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      season: json['season'] as int,
      round: json['round'] as int,
      raceName: json['race_name'] as String,
      raceDate: DateTime.parse(json['race_date'] as String),
      raceTime: json['race_time'] as String?,
      url: json['url'] as String?,
      circuit: Circuit.fromJson(json['circuit'] as Map<String, dynamic>),
      firstPracticeAt: _parseUtc(json['first_practice_at']),
      secondPracticeAt: _parseUtc(json['second_practice_at']),
      thirdPracticeAt: _parseUtc(json['third_practice_at']),
      qualifyingAt: _parseUtc(json['qualifying_at']),
      sprintAt: _parseUtc(json['sprint_at']),
      sprintQualifyingAt: _parseUtc(json['sprint_qualifying_at']),
    );
  }

  /// [raceDate] + [raceTime] combined into a single UTC instant, for
  /// sorting and for deciding whether a race is still upcoming.
  DateTime get startAtUtc {
    if (raceTime == null) {
      return DateTime.utc(raceDate.year, raceDate.month, raceDate.day);
    }
    final parts = raceTime!.split(':').map(int.parse).toList();
    return DateTime.utc(
      raceDate.year,
      raceDate.month,
      raceDate.day,
      parts[0],
      parts.length > 1 ? parts[1] : 0,
      parts.length > 2 ? parts[2] : 0,
    );
  }

  bool get isUpcoming => startAtUtc.isAfter(DateTime.now().toUtc());
  bool get isPast => !isUpcoming;
}
