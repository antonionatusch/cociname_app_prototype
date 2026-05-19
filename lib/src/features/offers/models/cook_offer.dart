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
  });

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
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
