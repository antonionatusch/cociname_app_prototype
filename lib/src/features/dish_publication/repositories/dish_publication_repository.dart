import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dish_publication.dart';
import '../models/enums.dart';

class DishPublicationRepository {
  DishPublicationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> uploadPhoto(File imageFile, {required int position}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$timestamp-$position.jpg';

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
    required List<String> photoStoragePaths,
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
      'photos':
          photoStoragePaths
              .asMap()
              .entries
              .map(
                (entry) => {
                  'storage_path': entry.value,
                  'public_url': null,
                  'position': entry.key + 1,
                },
              )
              .toList(),
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

  Future<List<DishPublication>> fetchOwnPublications() async {
    final response = await _client
        .from('dish_publications')
        .select(
          'id, title, description, price, available_quantity, is_active, zone_label, created_at, dish_photos(storage_path, public_url, position)',
        )
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => DishPublication.fromMap(
            item as Map<String, dynamic>,
            (path) => _client.storage.from('dish-photos').getPublicUrl(path),
          ),
        )
        .toList();
  }

  Future<void> setPublicationActive({
    required String publicationId,
    required bool isActive,
  }) async {
    await _client
        .from('dish_publications')
        .update({'is_active': isActive})
        .eq('id', publicationId);
  }

  Future<bool> fetchCookAvailability() async {
    final response =
        await _client
            .from('cook_profiles')
            .select('is_available')
            .maybeSingle();

    return response?['is_available'] as bool? ?? true;
  }

  Future<void> setCookAvailability(bool isAvailable) async {
    await _client.from('cook_profiles').update({'is_available': isAvailable});
  }
}
