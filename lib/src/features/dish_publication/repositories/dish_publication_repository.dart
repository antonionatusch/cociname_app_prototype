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

  String photoPublicUrl(String storagePath) {
    return _client.storage.from('dish-photos').getPublicUrl(storagePath);
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
          'id, title, description, price, available_quantity, is_active, latitude, longitude, zone_label, rating_average, rating_count, created_at, dish_photos(id, storage_path, public_url, position)',
        )
        .order('created_at', ascending: false);

    final publications =
        (response as List<dynamic>)
            .map(
              (item) => DishPublication.fromMap(
                item as Map<String, dynamic>,
                photoPublicUrl,
              ),
            )
            .toList();

    if (publications.isNotEmpty) {
      try {
        final allergenResult = await _client.rpc(
          'get_own_publication_allergens',
        );
        final allergenList = allergenResult as List<dynamic>;
        final allergenMap = <String, List<String>>{};
        for (final row in allergenList) {
          final rowMap = row as Map<String, dynamic>;
          final pubId = rowMap['publication_id'] as String?;
          final codes =
              (rowMap['allergen_codes'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          if (pubId != null) {
            allergenMap[pubId] = codes;
          }
        }
        for (var i = 0; i < publications.length; i++) {
          final codes = allergenMap[publications[i].id] ?? const <String>[];
          if (codes.isNotEmpty) {
            publications[i] = publications[i].copyWith(allergenCodes: codes);
          }
        }
      } catch (_) {}
    }

    return publications;
  }

  Future<void> addPublicationPhoto({
    required String publicationId,
    required String storagePath,
    required int position,
  }) async {
    await _client.rpc(
      'add_dish_publication_photo',
      params: {
        'p_publication_id': publicationId,
        'p_storage_path': storagePath,
        'p_position': position,
      },
    );
  }

  Future<void> deletePublicationPhoto({
    required String publicationId,
    required String storagePath,
  }) async {
    final deletedPath = await _client.rpc(
      'delete_dish_publication_photo',
      params: {
        'p_publication_id': publicationId,
        'p_storage_path': storagePath,
      },
    );

    final path = deletedPath?.toString() ?? storagePath;
    if (path.isNotEmpty) {
      await _client.storage.from('dish-photos').remove([path]);
    }
  }

  Future<void> reorderPublicationPhotos({
    required String publicationId,
    required List<String> orderedStoragePaths,
  }) async {
    await _client.rpc(
      'reorder_dish_publication_photos',
      params: {
        'p_publication_id': publicationId,
        'p_storage_paths': orderedStoragePaths,
      },
    );
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

  Future<void> updatePublication({
    required String publicationId,
    required String title,
    required String description,
    required double price,
    required int availableQuantity,
    double? latitude,
    double? longitude,
    String? zoneLabel,
  }) async {
    await _client.rpc(
      'update_dish_publication',
      params: {
        'p_publication_id': publicationId,
        'payload': {
          'title': title,
          'description': description,
          'price': price,
          'available_quantity': availableQuantity,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (zoneLabel != null) 'zone_label': zoneLabel,
        },
      },
    );
  }

  Future<void> deletePausedPublication(DishPublication publication) async {
    final storagePaths = await _client.rpc(
      'delete_paused_dish_publication',
      params: {'p_publication_id': publication.id},
    );

    final paths =
        storagePaths is List<dynamic>
            ? storagePaths.map((item) => item.toString()).toList()
            : publication.photos.map((item) => item.storagePath).toList();

    if (paths.isNotEmpty) {
      await _client.storage.from('dish-photos').remove(paths);
    }
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
    await _client.rpc(
      'set_cook_availability',
      params: {'p_is_available': isAvailable},
    );
  }
}
