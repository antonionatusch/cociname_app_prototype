import '../models/enums.dart';

const _foodLabels = {
  'pizza': 'Pizza',
  'empanada_queso_frita': 'Empanada de queso frita',
  'empanada_queso_integral': 'Empanada de queso integral',
  'hamburguesa': 'Hamburguesa',
  'cunape': 'Cuñapé',
  'unknown_food': 'Plato no reconocido',
};

const _ingredientLabels = {
  'harina_trigo': 'Harina de trigo',
  'harina_integral': 'Harina integral',
  'pan_hamburguesa': 'Pan de hamburguesa',
  'carne': 'Carne',
  'almidon_yuca': 'Almidón de yuca',
  'queso': 'Queso',
  'leche': 'Leche',
  'mantequilla': 'Mantequilla',
  'huevo': 'Huevo',
  'cacao': 'Cacao',
  'almendra': 'Almendra',
  'nuez': 'Nuez',
  'mani': 'Maní',
  'tomate': 'Tomate',
  'levadura': 'Levadura',
  'aceite': 'Aceite',
  'edulcorante': 'Edulcorante',
};

const _ingredientAliases = {
  'harina trigo': 'harina_trigo',
  'harina de trigo': 'harina_trigo',
  'harina integral': 'harina_integral',
  'pan hamburguesa': 'pan_hamburguesa',
  'pan de hamburguesa': 'pan_hamburguesa',
  'carne': 'carne',
  'almidon yuca': 'almidon_yuca',
  'almidon de yuca': 'almidon_yuca',
  'queso': 'queso',
  'leche': 'leche',
  'mantequilla': 'mantequilla',
  'huevo': 'huevo',
  'cacao': 'cacao',
  'almendra': 'almendra',
  'nuez': 'nuez',
  'mani': 'mani',
  'tomate': 'tomate',
  'levadura': 'levadura',
  'aceite': 'aceite',
  'edulcorante': 'edulcorante',
};

String displayFoodLabel(String code) {
  return _foodLabels[code] ?? _humanizeCode(code);
}

String displayIngredientLabel(String value) {
  return _ingredientLabels[value] ?? displayFreeTextLabel(value);
}

String displayVisionStatus(VisionStatus status) {
  return switch (status) {
    VisionStatus.recognized => 'Reconocido con alta confianza',
    VisionStatus.lowConfidence => 'Baja confianza; revísalo',
    VisionStatus.unknown => 'No se pudo reconocer',
    VisionStatus.manualOnly => 'Ingresado manualmente',
  };
}

String? knownIngredientCodeFromInput(String input) {
  final normalized = _normalizeForSearch(input);
  if (normalized.isEmpty) return null;
  return _ingredientAliases[normalized];
}

String displayFreeTextLabel(String value) {
  final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _humanizeCode(String code) {
  return displayFreeTextLabel(code.replaceAll('_', ' '));
}

String _normalizeForSearch(String value) {
  var normalized = value.toLowerCase().trim().replaceAll('_', ' ');
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  replacements.forEach((from, to) {
    normalized = normalized.replaceAll(from, to);
  });
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
