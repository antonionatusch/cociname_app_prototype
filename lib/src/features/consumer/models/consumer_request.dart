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
  final String? consumerDisplayName;
  final String? consumerZoneLabel;
  final int offerCount;
  final String? acceptedCookBusinessName;
  final String? acceptedDishTitle;
  final DateTime? completedAt;

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
    this.consumerDisplayName,
    this.consumerZoneLabel,
    this.offerCount = 0,
    this.acceptedCookBusinessName,
    this.acceptedDishTitle,
    this.completedAt,
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
      consumerDisplayName: map['consumer_display_name'] as String?,
      consumerZoneLabel: map['consumer_zone_label'] as String?,
      offerCount: (map['offer_count'] as num?)?.toInt() ?? 0,
      acceptedCookBusinessName: map['accepted_cook_business_name'] as String?,
      acceptedDishTitle: map['accepted_dish_title'] as String?,
      completedAt: _dateTime(map['completed_at']),
    );
  }

  static DateTime? _dateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }
}
