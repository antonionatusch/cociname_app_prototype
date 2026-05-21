class ConsumerRequest {
  final String id;
  final String queryText;
  final double targetPrice;
  final int requestedQuantity;
  final List<String> allergenFilters;
  final double maxRadiusKm;
  final double currentRadiusKm;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime createdAt;

  const ConsumerRequest({
    required this.id,
    required this.queryText,
    required this.targetPrice,
    this.requestedQuantity = 1,
    this.allergenFilters = const [],
    this.maxRadiusKm = 4,
    this.currentRadiusKm = 1,
    this.latitude,
    this.longitude,
    this.status = 'searching',
    required this.createdAt,
  });

  factory ConsumerRequest.fromMap(Map<String, dynamic> map) {
    return ConsumerRequest(
      id: map['id'] as String? ?? '',
      queryText: map['query_text'] as String? ?? '',
      targetPrice: (map['target_price'] as num?)?.toDouble() ?? 0,
      requestedQuantity: (map['requested_quantity'] as num?)?.toInt() ?? 1,
      allergenFilters:
          (map['allergen_filters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      maxRadiusKm: (map['max_radius_km'] as num?)?.toDouble() ?? 4,
      currentRadiusKm: (map['current_radius_km'] as num?)?.toDouble() ?? 1,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'searching',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
