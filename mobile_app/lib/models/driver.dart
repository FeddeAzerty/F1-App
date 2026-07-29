class Driver {
  const Driver({
    required this.driverRef,
    required this.givenName,
    required this.familyName,
    this.code,
    this.permanentNumber,
    this.dateOfBirth,
    this.nationality,
    this.url,
    this.photoUrl,
  });

  final String driverRef;
  final String? code;
  final int? permanentNumber;
  final String givenName;
  final String familyName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? url;

  /// Wikipedia-sourced headshot URL resolved by the backend. Empty string
  /// (not null) means the backend looked and found none, so treat both
  /// null and "" as "no photo".
  final String? photoUrl;

  String get fullName => '$givenName $familyName';

  String? get resolvedPhotoUrl =>
      (photoUrl != null && photoUrl!.isNotEmpty) ? photoUrl : null;

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverRef: json['driver_ref'] as String,
      code: json['code'] as String?,
      permanentNumber: json['permanent_number'] as int?,
      givenName: json['given_name'] as String,
      familyName: json['family_name'] as String,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      nationality: json['nationality'] as String?,
      url: json['url'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
