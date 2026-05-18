import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';

class IngredientRepository {
  IngredientRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Ingredient>> fetchIngredients() async {
    final response = await _client
        .from('ingredients')
        .select('id, code, name, aliases')
        .order('name');

    return (response as List<dynamic>)
        .map((item) => Ingredient.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Allergen>> fetchAllergens() async {
    final response = await _client
        .from('allergens')
        .select('id, code, name, description')
        .order('name');

    return (response as List<dynamic>)
        .map((item) => Allergen.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<IngredientAllergen>> fetchIngredientAllergenMap() async {
    final response = await _client
        .from('ingredient_allergens')
        .select('ingredient_id, allergen_id, certainty');

    return (response as List<dynamic>)
        .map((item) => IngredientAllergen.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
