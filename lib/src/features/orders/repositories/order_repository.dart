import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';

class OrderRepository {
  OrderRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> acceptOffer(String offerId) async {
    final result = await _client.rpc(
      'accept_cook_offer',
      params: {'p_offer_id': offerId},
    );
    return result as String;
  }

  Future<void> cancelOrder(String orderId) async {
    await _client.rpc('cancel_active_order', params: {'p_order_id': orderId});
  }

  Future<Order?> fetchActiveOrder() async {
    final response = await _client.rpc('get_active_order');

    final list = response as List<dynamic>;
    if (list.isEmpty) return null;

    final map = Map<String, dynamic>.from(list.first as Map);
    final storagePath = map['dish_photo_storage_path'] as String?;
    final publicUrl = map['dish_photo_public_url'] as String?;
    if ((publicUrl == null || publicUrl.isEmpty) &&
        storagePath != null &&
        storagePath.isNotEmpty) {
      map['dish_photo_public_url'] = _client.storage
          .from('dish-photos')
          .getPublicUrl(storagePath);
    }
    return Order.fromMap(map);
  }
}
