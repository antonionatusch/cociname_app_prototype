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
  final String orderPhase;
  final int? estimatedPreparationMinutes;
  final DateTime? preparationConfirmationDeadlineAt;
  final DateTime? preparationConfirmedAt;
  final DateTime? preparationDeadlineAt;
  final DateTime? readyAt;
  final DateTime? deliveryDeadlineAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final String? viewerRole;
  final String? deliveryPhotoStoragePath;
  final String? deliveryPhotoPublicUrl;
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
  final DateTime? serverNow;

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
    this.orderPhase = 'awaiting_preparation_confirmation',
    this.estimatedPreparationMinutes,
    this.preparationConfirmationDeadlineAt,
    this.preparationConfirmedAt,
    this.preparationDeadlineAt,
    this.readyAt,
    this.deliveryDeadlineAt,
    this.deliveredAt,
    this.completedAt,
    this.viewerRole,
    this.deliveryPhotoStoragePath,
    this.deliveryPhotoPublicUrl,
    this.serverNow,
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

  bool get isCookViewer => viewerRole == 'cook';

  bool get isConsumerViewer => viewerRole == 'consumer';

  bool get hasDeliveryPhoto =>
      deliveryPhotoPublicUrl != null && deliveryPhotoPublicUrl!.isNotEmpty;

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
      orderPhase:
          map['order_phase'] as String? ?? 'awaiting_preparation_confirmation',
      estimatedPreparationMinutes:
          (map['estimated_preparation_minutes'] as num?)?.toInt(),
      preparationConfirmationDeadlineAt: _dateTime(
        map['preparation_confirmation_deadline_at'],
      ),
      preparationConfirmedAt: _dateTime(map['preparation_confirmed_at']),
      preparationDeadlineAt: _dateTime(map['preparation_deadline_at']),
      readyAt: _dateTime(map['ready_at']),
      deliveryDeadlineAt: _dateTime(map['delivery_deadline_at']),
      deliveredAt: _dateTime(map['delivered_at']),
      completedAt: _dateTime(map['completed_at']),
      viewerRole: map['viewer_role'] as String?,
      deliveryPhotoStoragePath: map['delivery_photo_storage_path'] as String?,
      deliveryPhotoPublicUrl: map['delivery_photo_public_url'] as String?,
      serverNow: _dateTime(map['server_now']),
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

  static DateTime? _dateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }
}
