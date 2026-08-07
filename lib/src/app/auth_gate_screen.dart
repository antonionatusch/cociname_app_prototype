import 'package:flutter/material.dart';

import '../features/auth/repositories/auth_repository.dart';
import '../features/auth/views/login_screen.dart';
import '../features/onboarding/views/admin_console_screen.dart';
import '../features/onboarding/views/consumer_home_screen.dart';
import '../features/onboarding/views/cook_dashboard_screen.dart';
import '../features/onboarding/views/onboarding_flow_screen.dart';
import '../features/onboarding/views/role_hub_screen.dart';
import '../features/onboarding/repositories/onboarding_repository.dart';
import 'app_session_viewmodel.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({
    super.key,
    required this.authRepository,
    required this.onboardingRepository,
  });

  final AuthRepository authRepository;
  final OnboardingRepository onboardingRepository;

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late final AppSessionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AppSessionViewModel(
      widget.authRepository,
      widget.onboardingRepository,
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        switch (_viewModel.destination) {
          case AppSessionDestination.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AppSessionDestination.unauthenticated:
            return LoginScreen(authRepository: widget.authRepository);
          case AppSessionDestination.profileLoadError:
            return Scaffold(
              appBar: AppBar(title: const Text('No pudimos cargar tu perfil')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ocurrió un error al consultar tus perfiles. Intenta nuevamente.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _viewModel.profileLoadError ?? 'Error desconocido',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _viewModel.refresh,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          case AppSessionDestination.onboarding:
            return OnboardingFlowScreen(
              onboardingRepository: widget.onboardingRepository,
              onCompleted: _viewModel.refresh,
            );
          case AppSessionDestination.consumerHome:
            return ConsumerHomeScreen(sessionViewModel: _viewModel);
          case AppSessionDestination.cookHome:
            return CookDashboardScreen(sessionViewModel: _viewModel);
          case AppSessionDestination.adminHome:
            return AdminConsoleScreen(sessionViewModel: _viewModel);
          case AppSessionDestination.roleHub:
            return RoleHubScreen(
              sessionViewModel: _viewModel,
              profiles:
                  _viewModel.profiles
                      .where(
                        (profile) =>
                            profile.isActive && profile.onboardingCompleted,
                      )
                      .toList(),
            );
        }
      },
    );
  }
}
