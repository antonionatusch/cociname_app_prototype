import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/auth/repositories/auth_repository.dart';
import '../features/onboarding/models/profile_role.dart';
import '../features/onboarding/models/profile_summary.dart';
import '../features/onboarding/repositories/onboarding_repository.dart';

enum AppSessionDestination {
  loading,
  unauthenticated,
  onboarding,
  consumerHome,
  cookHome,
  adminHome,
  roleHub,
}

class AppSessionViewModel extends ChangeNotifier {
  AppSessionViewModel(this._authRepository, this._onboardingRepository);

  final AuthRepository _authRepository;
  final OnboardingRepository _onboardingRepository;

  StreamSubscription<dynamic>? _authSubscription;
  bool _loading = true;
  List<ProfileSummary> _profiles = const <ProfileSummary>[];

  bool get loading => _loading;
  bool get isAuthenticated => _authRepository.currentSession != null;
  List<ProfileSummary> get profiles => _profiles;
  String get displayName {
    final metadata = _authRepository.currentUser?.userMetadata;
    final fullName = metadata?['full_name'] as String?;
    final email = _authRepository.currentUser?.email;
    final phone = _authRepository.currentUser?.phone;
    return fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : (email ?? phone ?? 'Usuario CocinaME');
  }

  AppSessionDestination get destination {
    if (_loading) return AppSessionDestination.loading;
    if (!isAuthenticated) return AppSessionDestination.unauthenticated;

    final activeProfiles =
        _profiles
            .where((profile) => profile.isActive && profile.onboardingCompleted)
            .toList();

    if (activeProfiles.isEmpty) {
      return AppSessionDestination.onboarding;
    }

    if (activeProfiles.length > 1) {
      return AppSessionDestination.roleHub;
    }

    switch (activeProfiles.single.role) {
      case ProfileRole.consumer:
        return AppSessionDestination.consumerHome;
      case ProfileRole.cook:
        return AppSessionDestination.cookHome;
      case ProfileRole.admin:
        return AppSessionDestination.adminHome;
    }
  }

  Future<void> initialize() async {
    _authSubscription = _authRepository.authStateChanges.listen((_) {
      unawaited(refresh());
    });
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();

    if (!isAuthenticated) {
      _profiles = const <ProfileSummary>[];
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      _profiles = await _onboardingRepository.fetchOwnProfiles();
    } catch (_) {
      _profiles = const <ProfileSummary>[];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
