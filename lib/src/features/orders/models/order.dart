class Order {
  final String id;
  final String requestId;
  final String offerId;
  final String consumerProfileId;
  final String cookProfileId;
  final String publicationId;
  final double agreedPrice;
  final String status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.requestId,
    required this.offerId,
    required this.consumerProfileId,
    required this.cookProfileId,
    required this.publicationId,
    required this.agreedPrice,
    this.status = 'active',
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String? ?? '',
      requestId: map['request_id'] as String? ?? '',
      offerId: map['offer_id'] as String? ?? '',
      consumerProfileId: map['consumer_profile_id'] as String? ?? '',
      cookProfileId: map['cook_profile_id'] as String? ?? '',
      publicationId: map['publication_id'] as String? ?? '',
      agreedPrice: (map['agreed_price'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'active',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
