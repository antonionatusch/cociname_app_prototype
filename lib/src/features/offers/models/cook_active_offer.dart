class CookActiveOffer {
  final String id;
  final String requestId;
  final String publicationId;
  final String cookProfileId;
  final double price;
  final int? estimatedMinutes;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? dishTitle;
  final String? consumerDisplayName;
  final String? consumerQueryText;
  final double? consumerTargetPrice;
  final int requestedQuantity;
  final List<String> consumerAllergenFilters;
  final double? consumerLatitude;
  final double? consumerLongitude;

  const CookActiveOffer({
    required this.id,
    required this.requestId,
    required this.publicationId,
    required this.cookProfileId,
    required this.price,
    this.estimatedMinutes,
    this.message = '',
    this.status = 'pending',
    required this.createdAt,
    this.dishTitle,
    this.consumerDisplayName,
    this.consumerQueryText,
    this.consumerTargetPrice,
    this.requestedQuantity = 1,
    this.consumerAllergenFilters = const [],
    this.consumerLatitude,
    this.consumerLongitude,
  });

  factory CookActiveOffer.fromMap(Map<String, dynamic> map) {
    return CookActiveOffer(
      id: map['id'] as String? ?? '',
      requestId: map['request_id'] as String? ?? '',
      publicationId: map['publication_id'] as String? ?? '',
      cookProfileId: map['cook_profile_id'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt(),
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      dishTitle: map['dish_title'] as String?,
      consumerDisplayName: map['consumer_display_name'] as String?,
      consumerQueryText: map['consumer_query_text'] as String?,
      consumerTargetPrice: (map['consumer_target_price'] as num?)?.toDouble(),
      requestedQuantity: (map['requested_quantity'] as num?)?.toInt() ?? 1,
      consumerAllergenFilters:
          (map['consumer_allergen_filters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      consumerLatitude: (map['consumer_latitude'] as num?)?.toDouble(),
      consumerLongitude: (map['consumer_longitude'] as num?)?.toDouble(),
    );
  }
}
