class Constructor {
  const Constructor({
    required this.constructorRef,
    required this.name,
    this.nationality,
    this.url,
  });

  final String constructorRef;
  final String name;
  final String? nationality;
  final String? url;

  factory Constructor.fromJson(Map<String, dynamic> json) {
    return Constructor(
      constructorRef: json['constructor_ref'] as String,
      name: json['name'] as String,
      nationality: json['nationality'] as String?,
      url: json['url'] as String?,
    );
  }
}
