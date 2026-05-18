class Ingredient {
  final String id;
  final String code;
  final String name;
  final List<String> aliases;

  const Ingredient({
    required this.id,
    required this.code,
    required this.name,
    this.aliases = const [],
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      aliases: (map['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class Allergen {
  final String id;
  final String code;
  final String name;
  final String description;

  const Allergen({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
  });

  factory Allergen.fromMap(Map<String, dynamic> map) {
    return Allergen(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
    );
  }
}

class IngredientAllergen {
  final String ingredientId;
  final String allergenId;
  final String certainty;

  const IngredientAllergen({
    required this.ingredientId,
    required this.allergenId,
    this.certainty = 'contains',
  });

  factory IngredientAllergen.fromMap(Map<String, dynamic> map) {
    return IngredientAllergen(
      ingredientId: map['ingredient_id'] as String,
      allergenId: map['allergen_id'] as String,
      certainty: map['certainty'] as String? ?? 'contains',
    );
  }
}
