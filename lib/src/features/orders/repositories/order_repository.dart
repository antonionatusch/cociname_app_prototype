import 'dart:io';

import 'package:image_picker/image_picker.dart';
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
    return (result as String?) ?? '';
  }

  Future<void> cancelOrder(String orderId) async {
    await _client.rpc('cancel_active_order', params: {'p_order_id': orderId});
  }

  Future<void> confirmPreparation(String orderId) async {
    await _client.rpc(
      'confirm_order_preparation',
      params: {'p_order_id': orderId},
    );
  }

  Future<void> markReady(String orderId) async {
    await _client.rpc('mark_order_ready', params: {'p_order_id': orderId});
  }

  Future<void> confirmDelivery(String orderId) async {
    await _client.rpc(
      'confirm_order_delivery',
      params: {'p_order_id': orderId},
    );
  }

  Future<void> uploadDeliveryPhoto({
    required String orderId,
    required XFile photo,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Usuario no autenticado');

    final nameParts = photo.name.split('.');
    final extension = nameParts.length > 1 ? nameParts.last : 'jpg';
    final storagePath =
        '$userId/$orderId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage
        .from('order-delivery-photos')
        .upload(storagePath, File(photo.path));

    await _client.rpc(
      'register_order_delivery_photo',
      params: {'p_order_id': orderId, 'p_storage_path': storagePath},
    );
  }

  Future<String?> fetchOrderStatus(String orderId) async {
    final result = await _client.rpc(
      'get_order_status',
      params: {'p_order_id': orderId},
    );
    return result as String?;
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
    final deliveryStoragePath = map['delivery_photo_storage_path'] as String?;
    final deliveryPublicUrl = map['delivery_photo_public_url'] as String?;
    if ((deliveryPublicUrl == null || deliveryPublicUrl.isEmpty) &&
        deliveryStoragePath != null &&
        deliveryStoragePath.isNotEmpty) {
      map['delivery_photo_public_url'] = _client.storage
          .from('order-delivery-photos')
          .getPublicUrl(deliveryStoragePath);
    }
    return Order.fromMap(map);
  }
}
