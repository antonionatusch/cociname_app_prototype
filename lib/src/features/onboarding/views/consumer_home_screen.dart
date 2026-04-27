import 'package:flutter/material.dart';

import '../../../app/app_session_viewmodel.dart';

class ConsumerHomeScreen extends StatelessWidget {
  const ConsumerHomeScreen({super.key, required this.sessionViewModel});

  final AppSessionViewModel sessionViewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio consumidor'),
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
              'Hola, ${sessionViewModel.displayName}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu perfil de consumidor ya esta creado. Esta pantalla queda como placeholder para los siguientes casos de uso de exploracion y pedidos.',
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Proximo paso: explorar ofertas, aplicar filtros y consultar detalle de platos.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
