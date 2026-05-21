class DishPublicationPhoto {
  const DishPublicationPhoto({
    this.id,
    required this.storagePath,
    required this.publicUrl,
    required this.position,
  });

  final String? id;
  final String storagePath;
  final String publicUrl;
  final int position;

  factory DishPublicationPhoto.fromMap(
    Map<String, dynamic> map,
    String Function(String path) publicUrlBuilder,
  ) {
    final storagePath = map['storage_path'] as String? ?? '';
    return DishPublicationPhoto(
      id: map['id'] as String?,
      storagePath: storagePath,
      publicUrl: map['public_url'] as String? ?? publicUrlBuilder(storagePath),
      position: (map['position'] as num?)?.toInt() ?? 1,
    );
  }
}

class DishPublication {
  const DishPublication({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.availableQuantity,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.zoneLabel,
    this.ratingAverage = 5.0,
    this.ratingCount = 0,
    required this.photos,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final int availableQuantity;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final String? zoneLabel;
  final double ratingAverage;
  final int ratingCount;
  final List<DishPublicationPhoto> photos;

  DishPublicationPhoto? get coverPhoto => photos.isEmpty ? null : photos.first;

  factory DishPublication.fromMap(
    Map<String, dynamic> map,
    String Function(String path) publicUrlBuilder,
  ) {
    final rawPhotos =
        (map['dish_photos'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (photo) => DishPublicationPhoto.fromMap(photo, publicUrlBuilder),
            )
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    final priceValue = map['price'];
    final latRaw = map['latitude'];
    final lngRaw = map['longitude'];
    return DishPublication(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price:
          priceValue is num
              ? priceValue.toDouble()
              : double.tryParse(priceValue?.toString() ?? '') ?? 0,
      availableQuantity: map['available_quantity'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? false,
      latitude: latRaw is num ? latRaw.toDouble() : null,
      longitude: lngRaw is num ? lngRaw.toDouble() : null,
      zoneLabel: map['zone_label'] as String?,
      ratingAverage: (map['rating_average'] as num?)?.toDouble() ?? 5.0,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
      photos: rawPhotos,
    );
  }

  DishPublication copyWith({
    String? title,
    String? description,
    double? price,
    int? availableQuantity,
    bool? isActive,
    double? latitude,
    double? longitude,
    String? zoneLabel,
    double? ratingAverage,
    int? ratingCount,
    List<DishPublicationPhoto>? photos,
  }) {
    return DishPublication(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      isActive: isActive ?? this.isActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zoneLabel: zoneLabel ?? this.zoneLabel,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      photos: photos ?? this.photos,
    );
  }
}
