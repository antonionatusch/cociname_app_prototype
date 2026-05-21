import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cook_offer.dart';

class OfferRepository {
  OfferRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> createOffer({
    required String requestId,
    required String publicationId,
    required double price,
    int? estimatedMinutes,
    String message = '',
  }) async {
    final payload = {
      'request_id': requestId,
      'publication_id': publicationId,
      'price': price,
      'estimated_minutes': estimatedMinutes,
      'message': message,
    };

    final result = await _client.rpc(
      'create_cook_offer',
      params: {'payload': payload},
    );

    return result as String;
  }

  Future<List<CookOffer>> fetchOffersForRequest(String requestId) async {
    final response = await _client.rpc(
      'get_offers_for_request',
      params: {'p_request_id': requestId},
    );

    return (response as List<dynamic>).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final rawPhotos = map['dish_photos'] as List<dynamic>?;
      if (rawPhotos != null) {
        map['dish_photos'] =
            rawPhotos.whereType<Map>().map((photo) {
              final photoMap = Map<String, dynamic>.from(photo);
              final storagePath = photoMap['storage_path'] as String?;
              final publicUrl = photoMap['public_url'] as String?;
              if ((publicUrl == null || publicUrl.isEmpty) &&
                  storagePath != null &&
                  storagePath.isNotEmpty) {
                photoMap['public_url'] = _client.storage
                    .from('dish-photos')
                    .getPublicUrl(storagePath);
              }
              return photoMap;
            }).toList();
      }
      final storagePath = map['dish_photo_storage_path'] as String?;
      final publicUrl = map['dish_photo_public_url'] as String?;
      if ((publicUrl == null || publicUrl.isEmpty) &&
          storagePath != null &&
          storagePath.isNotEmpty) {
        map['dish_photo_public_url'] = _client.storage
            .from('dish-photos')
            .getPublicUrl(storagePath);
      }
      return CookOffer.fromMap(map);
    }).toList();
  }
}
