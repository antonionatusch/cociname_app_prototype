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

  Future<Order?> fetchActiveOrder() async {
    final response = await _client
        .from('orders')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromMap(response);
  }
}
