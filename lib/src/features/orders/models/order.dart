class Order {
  final String id;
  final String requestId;
  final String offerId;
  final String consumerProfileId;
  final String cookProfileId;
  final String publicationId;
  final double agreedPrice;
  final int requestedQuantity;
  final String status;
  final DateTime createdAt;
  final String? dishTitle;
  final String? cookBusinessName;
  final String? consumerDisplayName;
  final double? publicationLatitude;
  final double? publicationLongitude;
  final double? consumerLatitude;
  final double? consumerLongitude;
  final String? dishPhotoStoragePath;
  final String? dishPhotoPublicUrl;

  const Order({
    required this.id,
    required this.requestId,
    required this.offerId,
    required this.consumerProfileId,
    required this.cookProfileId,
    required this.publicationId,
    required this.agreedPrice,
    this.requestedQuantity = 1,
    this.status = 'active',
    required this.createdAt,
    this.dishTitle,
    this.cookBusinessName,
    this.consumerDisplayName,
    this.publicationLatitude,
    this.publicationLongitude,
    this.consumerLatitude,
    this.consumerLongitude,
    this.dishPhotoStoragePath,
    this.dishPhotoPublicUrl,
  });

  bool get hasPublicationLocation =>
      publicationLatitude != null && publicationLongitude != null;

  bool get hasConsumerLocation =>
      consumerLatitude != null && consumerLongitude != null;

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String? ?? '',
      requestId: map['request_id'] as String? ?? '',
      offerId: map['offer_id'] as String? ?? '',
      consumerProfileId: map['consumer_profile_id'] as String? ?? '',
      cookProfileId: map['cook_profile_id'] as String? ?? '',
      publicationId: map['publication_id'] as String? ?? '',
      agreedPrice: (map['agreed_price'] as num?)?.toDouble() ?? 0,
      requestedQuantity: (map['requested_quantity'] as num?)?.toInt() ?? 1,
      status: map['status'] as String? ?? 'active',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      dishTitle: map['dish_title'] as String?,
      cookBusinessName: map['cook_business_name'] as String?,
      consumerDisplayName: map['consumer_display_name'] as String?,
      publicationLatitude: (map['publication_latitude'] as num?)?.toDouble(),
      publicationLongitude: (map['publication_longitude'] as num?)?.toDouble(),
      consumerLatitude: (map['consumer_latitude'] as num?)?.toDouble(),
      consumerLongitude: (map['consumer_longitude'] as num?)?.toDouble(),
      dishPhotoStoragePath: map['dish_photo_storage_path'] as String?,
      dishPhotoPublicUrl: map['dish_photo_public_url'] as String?,
    );
  }
}
