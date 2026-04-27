class ConsumerOnboardingData {
  const ConsumerOnboardingData({
    required this.zoneLabel,
    required this.preferredFoodTypes,
    required this.appUsageFrequency,
    required this.orderMotivations,
    required this.allergenFilters,
    required this.deliveryPreferences,
    required this.paymentPreferences,
  });

  final String zoneLabel;
  final List<String> preferredFoodTypes;
  final String appUsageFrequency;
  final List<String> orderMotivations;
  final List<String> allergenFilters;
  final List<String> deliveryPreferences;
  final List<String> paymentPreferences;

  Map<String, dynamic> toPayload() {
    return {
      'zone_label': zoneLabel,
      'preferred_food_types': preferredFoodTypes,
      'app_usage_frequency': appUsageFrequency,
      'order_motivations': orderMotivations,
      'allergen_filters': allergenFilters,
      'delivery_preferences': deliveryPreferences,
      'payment_preferences': paymentPreferences,
    };
  }
}
