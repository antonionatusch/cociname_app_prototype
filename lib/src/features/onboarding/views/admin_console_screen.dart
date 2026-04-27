import 'package:flutter/material.dart';

import '../../../app/app_session_viewmodel.dart';

class AdminConsoleScreen extends StatelessWidget {
  const AdminConsoleScreen({super.key, required this.sessionViewModel});

  final AppSessionViewModel sessionViewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consola administrativa'),
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
              'Perfil administrativo activo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta consola queda como placeholder del caso de uso de supervision de contenido e incidencias operativas.',
            ),
          ],
        ),
      ),
    );
  }
}
