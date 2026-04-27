class CookOnboardingData {
  const CookOnboardingData({
    required this.businessName,
    required this.dishTypes,
    required this.prepLeadTime,
    required this.weeklyOrderVolume,
    required this.deliveryMethods,
    required this.mainPainPoints,
    required this.operatingZone,
  });

  final String businessName;
  final List<String> dishTypes;
  final String prepLeadTime;
  final String weeklyOrderVolume;
  final List<String> deliveryMethods;
  final List<String> mainPainPoints;
  final String operatingZone;

  Map<String, dynamic> toPayload() {
    return {
      'business_name': businessName,
      'dish_types': dishTypes,
      'prep_lead_time': prepLeadTime,
      'weekly_order_volume': weeklyOrderVolume,
      'delivery_methods': deliveryMethods,
      'main_pain_points': mainPainPoints,
      'operating_zone': operatingZone,
    };
  }
}
