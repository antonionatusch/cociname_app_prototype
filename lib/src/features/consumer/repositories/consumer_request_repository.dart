import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consumer_request.dart';

class ConsumerRequestRepository {
  ConsumerRequestRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> createRequest({
    required String queryText,
    required double targetPrice,
    required List<String> allergenFilters,
    required double maxRadiusKm,
    required double currentRadiusKm,
    required double? latitude,
    required double? longitude,
  }) async {
    final payload = {
      'query_text': queryText,
      'target_price': targetPrice,
      'allergen_filters': allergenFilters,
      'max_radius_km': maxRadiusKm,
      'current_radius_km': currentRadiusKm,
      'latitude': latitude,
      'longitude': longitude,
    };

    final result = await _client.rpc(
      'create_consumer_request',
      params: {'payload': payload},
    );

    return result as String;
  }

  Future<List<ConsumerRequest>> fetchActiveRequest() async {
    final response = await _client
        .from('consumer_requests')
        .select()
        .inFilter('status', ['searching', 'matched'])
        .order('created_at', ascending: false)
        .limit(1);

    final list = response as List<dynamic>;
    if (list.isEmpty) return [];

    return list
        .map((item) => ConsumerRequest.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelRequest(String requestId) async {
    await _client.rpc(
      'cancel_consumer_request',
      params: {'p_request_id': requestId},
    );
  }
}
