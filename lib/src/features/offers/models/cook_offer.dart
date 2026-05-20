class CookOffer {
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
  final String? dishDescription;
  final String? dishPhotoStoragePath;
  final String? dishPhotoPublicUrl;
  final String? cookBusinessName;
  final double? cookRatingAverage;
  final double? publicationLatitude;
  final double? publicationLongitude;
  final String? publicationZoneLabel;
  final double? distanceKm;
  final List<String> allergenCodes;

  const CookOffer({
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
    this.dishDescription,
    this.dishPhotoStoragePath,
    this.dishPhotoPublicUrl,
    this.cookBusinessName,
    this.cookRatingAverage,
    this.publicationLatitude,
    this.publicationLongitude,
    this.publicationZoneLabel,
    this.distanceKm,
    this.allergenCodes = const [],
  });

  bool get hasPublicationLocation =>
      publicationLatitude != null && publicationLongitude != null;

  factory CookOffer.fromMap(Map<String, dynamic> map) {
    return CookOffer(
      id: map['id'] as String? ?? '',
      requestId: map['request_id'] as String? ?? '',
      publicationId: map['publication_id'] as String? ?? '',
      cookProfileId: map['cook_profile_id'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      estimatedMinutes: map['estimated_minutes'] as int?,
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      dishTitle: map['dish_title'] as String?,
      dishDescription: map['dish_description'] as String?,
      dishPhotoStoragePath: map['dish_photo_storage_path'] as String?,
      dishPhotoPublicUrl: map['dish_photo_public_url'] as String?,
      cookBusinessName: map['cook_business_name'] as String?,
      cookRatingAverage: (map['cook_rating_average'] as num?)?.toDouble(),
      publicationLatitude: (map['publication_latitude'] as num?)?.toDouble(),
      publicationLongitude: (map['publication_longitude'] as num?)?.toDouble(),
      publicationZoneLabel: map['publication_zone_label'] as String?,
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      allergenCodes:
          (map['allergen_codes'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }
}
