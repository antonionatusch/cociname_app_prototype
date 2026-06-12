import 'enums.dart';

class DishIngredient {
  final String? ingredientId;
  final String? customName;
  final IngredientSource source;
  final bool isConfirmedByCook;

  const DishIngredient({
    this.ingredientId,
    this.customName,
    required this.source,
    this.isConfirmedByCook = false,
  });

  bool get isKnown => ingredientId != null;
  String get displayName => customName ?? ingredientId ?? '';

  Map<String, dynamic> toPayload() {
    return {
      if (ingredientId != null) 'code': ingredientId,
      if (customName != null) 'name': customName,
      'source': source.databaseValue,
      'is_confirmed_by_cook': isConfirmedByCook,
    };
  }
}
