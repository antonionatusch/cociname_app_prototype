import 'package:flutter/material.dart';

import '../../../app/app_session_viewmodel.dart';
import '../models/profile_role.dart';
import '../models/profile_summary.dart';
import 'admin_console_screen.dart';
import 'consumer_home_screen.dart';
import 'cook_dashboard_screen.dart';

class RoleHubScreen extends StatelessWidget {
  const RoleHubScreen({
    super.key,
    required this.sessionViewModel,
    required this.profiles,
  });

  final AppSessionViewModel sessionViewModel;
  final List<ProfileSummary> profiles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir perfil'),
        actions: [
          IconButton(
            onPressed: sessionViewModel.signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Tienes varios perfiles activos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona con que vista quieres continuar, ${sessionViewModel.displayName}.',
          ),
          const SizedBox(height: 20),
          for (final profile in profiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_iconForRole(profile.role)),
                  ),
                  title: Text(profile.role.label),
                  subtitle: Text(profile.role.shortDescription),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _screenForRole(profile.role),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _screenForRole(ProfileRole role) {
    switch (role) {
      case ProfileRole.consumer:
        return ConsumerHomeScreen(sessionViewModel: sessionViewModel);
      case ProfileRole.cook:
        return CookDashboardScreen(sessionViewModel: sessionViewModel);
      case ProfileRole.admin:
        return AdminConsoleScreen(sessionViewModel: sessionViewModel);
    }
  }

  IconData _iconForRole(ProfileRole role) {
    switch (role) {
      case ProfileRole.consumer:
        return Icons.shopping_bag_outlined;
      case ProfileRole.cook:
        return Icons.storefront_outlined;
      case ProfileRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}
