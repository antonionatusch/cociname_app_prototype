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
    final response = await _client
        .from('cook_offers')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => CookOffer.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
