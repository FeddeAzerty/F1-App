class Circuit {
  const Circuit({
    required this.circuitRef,
    required this.name,
    this.locality,
    this.country,
    this.latitude,
    this.longitude,
    this.url,
  });

  final String circuitRef;
  final String name;
  final String? locality;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? url;

  factory Circuit.fromJson(Map<String, dynamic> json) {
    return Circuit(
      circuitRef: json['circuit_ref'] as String,
      name: json['name'] as String,
      locality: json['locality'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      url: json['url'] as String?,
    );
  }
}
