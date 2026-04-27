import 'profile_role.dart';

class ProfileSummary {
  const ProfileSummary({
    required this.id,
    required this.role,
    required this.onboardingCompleted,
    required this.isActive,
  });

  final String id;
  final ProfileRole role;
  final bool onboardingCompleted;
  final bool isActive;

  factory ProfileSummary.fromMap(Map<String, dynamic> map) {
    return ProfileSummary(
      id: map['id'] as String,
      role: ProfileRoleX.fromDatabaseValue(map['profile_type'] as String),
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
