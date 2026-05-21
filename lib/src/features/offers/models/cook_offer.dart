enum OfferAllergenWarningType { contains, mayContain }

class OfferIngredientItem {
  final String name;
  final String source;
  final bool isConfirmedByCook;

  const OfferIngredientItem({
    required this.name,
    required this.source,
    required this.isConfirmedByCook,
  });

  factory OfferIngredientItem.fromMap(Map<String, dynamic> map) {
    return OfferIngredientItem(
      name: map['name'] as String? ?? 'Ingrediente',
      source: map['source'] as String? ?? '',
      isConfirmedByCook: map['is_confirmed_by_cook'] as bool? ?? false,
    );
  }
}

class OfferAllergenWarning {
  final String code;
  final String name;
  final String ingredientName;
  final OfferAllergenWarningType type;
  final String source;
  final String certainty;

  const OfferAllergenWarning({
    required this.code,
    required this.name,
    required this.ingredientName,
    required this.type,
    this.source = '',
    this.certainty = 'contains',
  });

  factory OfferAllergenWarning.fromMap(Map<String, dynamic> map) {
    final rawType = map['warning_type'] as String? ?? 'may_contain';
    return OfferAllergenWarning(
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? map['code'] as String? ?? 'Alergeno',
      ingredientName: map['ingredient_name'] as String? ?? 'Ingrediente',
      type:
          rawType == 'contains'
              ? OfferAllergenWarningType.contains
              : OfferAllergenWarningType.mayContain,
      source: map['source'] as String? ?? '',
      certainty: map['certainty'] as String? ?? 'contains',
    );
  }

  factory OfferAllergenWarning.fromCode(String code) {
    return OfferAllergenWarning(
      code: code,
      name: code,
      ingredientName: 'Ingrediente no especificado',
      type: OfferAllergenWarningType.mayContain,
    );
  }
}

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
  final List<OfferIngredientItem> ingredients;
  final List<OfferAllergenWarning> allergenWarnings;

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
    this.ingredients = const [],
    this.allergenWarnings = const [],
  });

  bool get hasPublicationLocation =>
      publicationLatitude != null && publicationLongitude != null;

  List<OfferAllergenWarning> get containsWarnings =>
      allergenWarnings
          .where((item) => item.type == OfferAllergenWarningType.contains)
          .toList();

  List<OfferAllergenWarning> get mayContainWarnings =>
      allergenWarnings
          .where((item) => item.type == OfferAllergenWarningType.mayContain)
          .toList();

  factory CookOffer.fromMap(Map<String, dynamic> map) {
    final allergenCodes =
        (map['allergen_codes'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final warnings =
        (map['allergen_warnings'] as List<dynamic>?)
            ?.whereType<Map>()
            .map(
              (item) =>
                  OfferAllergenWarning.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList() ??
        const <OfferAllergenWarning>[];

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
      allergenCodes: allergenCodes,
      ingredients:
          (map['dish_ingredient_items'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (item) => OfferIngredientItem.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          const [],
      allergenWarnings:
          warnings.isNotEmpty
              ? warnings
              : allergenCodes.map(OfferAllergenWarning.fromCode).toList(),
    );
  }
}
