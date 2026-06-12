class AvailableCookMarker {
  const AvailableCookMarker({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  factory AvailableCookMarker.fromMap(Map<String, dynamic> map) {
    return AvailableCookMarker(
      id: map['id'] as String? ?? '',
      name: map['business_name'] as String? ?? 'Cocinero disponible',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
