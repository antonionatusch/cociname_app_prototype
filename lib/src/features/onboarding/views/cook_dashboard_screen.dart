import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_session_viewmodel.dart';
import '../../dish_publication/repositories/dish_publication_repository.dart';
import '../../dish_publication/repositories/ingredient_repository.dart';
import '../../dish_publication/services/location_service.dart';
import '../../dish_publication/services/tflite_vision_classifier_service.dart';
import '../../dish_publication/viewmodels/publish_dish_viewmodel.dart';
import '../../dish_publication/views/publish_dish_screen.dart';

class CookDashboardScreen extends StatelessWidget {
  const CookDashboardScreen({super.key, required this.sessionViewModel});

  final AppSessionViewModel sessionViewModel;

  Future<void> _navigateToPublish(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final classifier = context.read<TfliteVisionClassifierService>();
    final locationService = context.read<LocationService>();
    final publicationRepo = context.read<DishPublicationRepository>();
    final ingredientRepo = context.read<IngredientRepository>();

    if (!classifier.isInitialized) {
      await classifier.initialize();
    }

    final result = await navigator.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PublishDishViewModel(
            classifier: classifier,
            locationService: locationService,
            publicationRepository: publicationRepo,
            ingredientRepository: ingredientRepo,
          ),
          child: const PublishDishScreen(),
        ),
      ),
    );

    if (result == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Plato publicado exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel emprendedor'),
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
              'Tu perfil de emprendedor ya esta activo con la suscripcion Base.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToPublish(context),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Publicar plato'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

