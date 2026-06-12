const Map<String, String> _allergenDisplayNames = {
  'gluten': 'Gluten',
  'lacteos': 'Lácteos',
  'huevo': 'Huevo',
  'frutos_secos': 'Frutos secos',
  'mani': 'Maní',
  'soya': 'Soya',
};

String allergenDisplayName(String code) {
  return _allergenDisplayNames[code] ??
      code[0].toUpperCase() + code.substring(1);
}

String formatAllergenFilters(List<String> codes) {
  if (codes.isEmpty) return 'Sin alergias declaradas';
  return codes.map(allergenDisplayName).join(', ');
}
