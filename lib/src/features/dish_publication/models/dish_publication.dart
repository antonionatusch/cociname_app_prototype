class DishPublicationPhoto {
  const DishPublicationPhoto({
    required this.storagePath,
    required this.publicUrl,
    required this.position,
  });

  final String storagePath;
  final String publicUrl;
  final int position;

  factory DishPublicationPhoto.fromMap(
    Map<String, dynamic> map,
    String Function(String path) publicUrlBuilder,
  ) {
    final storagePath = map['storage_path'] as String? ?? '';
    return DishPublicationPhoto(
      storagePath: storagePath,
      publicUrl: map['public_url'] as String? ?? publicUrlBuilder(storagePath),
      position: map['position'] as int? ?? 1,
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
    required this.zoneLabel,
    required this.photos,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final int availableQuantity;
  final bool isActive;
  final String? zoneLabel;
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
      zoneLabel: map['zone_label'] as String?,
      photos: rawPhotos,
    );
  }

  DishPublication copyWith({
    String? title,
    String? description,
    double? price,
    int? availableQuantity,
    bool? isActive,
  }) {
    return DishPublication(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      isActive: isActive ?? this.isActive,
      zoneLabel: zoneLabel,
      photos: photos,
    );
  }
}
