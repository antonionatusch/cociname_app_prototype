import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consumer_onboarding_data.dart';
import '../models/cook_onboarding_data.dart';
import '../models/profile_role.dart';
import '../models/profile_summary.dart';

class OnboardingRepository {
  OnboardingRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ProfileSummary>> fetchOwnProfiles() async {
    final response = await _client
        .from('profiles')
        .select('id, profile_type, onboarding_completed, is_active')
        .order('created_at');

    return (response as List<dynamic>)
        .map((item) => ProfileSummary.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> completeOnboarding({
    required Set<ProfileRole> roles,
    ConsumerOnboardingData? consumerData,
    CookOnboardingData? cookData,
  }) async {
    await _client.rpc(
      'complete_profile_onboarding',
      params: {
        'selected_roles': roles.map((role) => role.databaseValue).toList(),
        'consumer_payload': consumerData?.toPayload() ?? <String, dynamic>{},
        'cook_payload': cookData?.toPayload() ?? <String, dynamic>{},
      },
    );
  }
}
