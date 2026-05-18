import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';

class DishPublicationRepository {
  DishPublicationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> uploadPhoto(File imageFile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$timestamp.jpg';

    await _client.storage.from('dish-photos').upload(path, imageFile);

    return path;
  }

  Future<String> createPublication({
    required String title,
    required String description,
    required double price,
    required int availableQuantity,
    required String categoryCode,
    required VisionStatus visionStatus,
    required double? visionConfidence,
    required String? detectedLabel,
    required String? manualFoodName,
    required double? latitude,
    required double? longitude,
    required String? zoneLabel,
    required String photoStoragePath,
    required List<Map<String, dynamic>> ingredients,
    required List<Map<String, dynamic>> customIngredients,
    required Map<String, dynamic>? visionLog,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'price': price,
      'available_quantity': availableQuantity,
      'category_code': categoryCode,
      'vision_status': visionStatus.databaseValue,
      'vision_confidence': visionConfidence,
      'detected_label': detectedLabel,
      'manual_food_name': manualFoodName,
      'latitude': latitude,
      'longitude': longitude,
      'zone_label': zoneLabel,
      'photo': {
        'storage_path': photoStoragePath,
        'public_url': null,
      },
      'ingredients': ingredients,
      'custom_ingredients': customIngredients,
      'vision_log': visionLog,
    };

    final result = await _client.rpc(
      'create_dish_publication',
      params: {'payload': payload},
    );

    return result as String;
  }
}
