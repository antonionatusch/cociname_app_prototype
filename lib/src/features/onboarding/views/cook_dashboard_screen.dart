import 'package:flutter/material.dart';

import '../../../app/app_session_viewmodel.dart';

class CookDashboardScreen extends StatelessWidget {
  const CookDashboardScreen({super.key, required this.sessionViewModel});

  final AppSessionViewModel sessionViewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel cocinero'),
        actions: [
          IconButton(
            onPressed: sessionViewModel.signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${sessionViewModel.displayName}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu perfil de cocinero ya esta activo con la suscripcion Base. Esta pantalla queda lista como entrada a publicaciones, solicitudes y metricas.',
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Proximo paso: gestionar publicaciones de platos, ingredientes y alertas preventivas.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
