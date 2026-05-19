import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_session_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../dish_publication/models/dish_publication.dart';
import '../../dish_publication/repositories/dish_publication_repository.dart';
import '../../dish_publication/repositories/ingredient_repository.dart';
import '../../dish_publication/services/location_service.dart';
import '../../dish_publication/services/tflite_vision_classifier_service.dart';
import '../../dish_publication/viewmodels/publish_dish_viewmodel.dart';
import '../../dish_publication/views/publish_dish_screen.dart';
import '../viewmodels/cook_dashboard_viewmodel.dart';

class CookDashboardScreen extends StatefulWidget {
  const CookDashboardScreen({super.key, required this.sessionViewModel});

  final AppSessionViewModel sessionViewModel;

  @override
  State<CookDashboardScreen> createState() => _CookDashboardScreenState();
}

class _CookDashboardScreenState extends State<CookDashboardScreen> {
  CookDashboardViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= CookDashboardViewModel(
      publicationRepository: context.read<DishPublicationRepository>(),
    )..load();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _navigateToPublish(BuildContext context) async {
    final classifier = context.read<TfliteVisionClassifierService>();
    final locationService = context.read<LocationService>();
    final publicationRepo = context.read<DishPublicationRepository>();
    final ingredientRepo = context.read<IngredientRepository>();

    if (!classifier.isInitialized) {
      await classifier.initialize();
    }

    if (!context.mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create:
                  (_) => PublishDishViewModel(
                    classifier: classifier,
                    locationService: locationService,
                    publicationRepository: publicationRepo,
                    ingredientRepository: ingredientRepo,
                  ),
              child: const PublishDishScreen(),
            ),
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plato publicado exitosamente')),
      );
      await _viewModel?.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel emprendedor'),
          actions: [
            IconButton(
              onPressed: widget.sessionViewModel.signOut,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesion',
            ),
          ],
        ),
        body: Consumer<CookDashboardViewModel>(
          builder: (context, vm, _) {
            return RefreshIndicator(
              onRefresh: vm.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _AvailabilityHeader(
                    displayName: widget.sessionViewModel.displayName,
                    isAvailable: vm.isAvailable,
                    onChanged: vm.setAvailability,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToPublish(context),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Publicar plato'),
                    ),
                  ),
                  if (vm.error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: vm.error!),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tus publicaciones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (vm.isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!vm.isLoading && vm.publications.isEmpty)
                    const _EmptyPublicationsCard(),
                  ...vm.publications.map(
                    (publication) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PublicationCard(
                        publication: publication,
                        onActiveChanged:
                            (value) =>
                                vm.setPublicationActive(publication.id, value),
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => DishPublicationDetailScreen(
                                      publication: publication,
                                      onActiveChanged:
                                          (value) => vm.setPublicationActive(
                                            publication.id,
                                            value,
                                          ),
                                    ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvailabilityHeader extends StatelessWidget {
  const _AvailabilityHeader({
    required this.displayName,
    required this.isAvailable,
    required this.onChanged,
  });

  final String displayName;
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = isAvailable ? AppTheme.success : AppTheme.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $displayName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAvailable
                        ? 'Estas libre para recibir oportunidades.'
                        : 'Estas ocupado; pausaremos nuevas oportunidades.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(!isAvailable),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 128,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: statusColor, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment:
                      isAvailable
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Text(
                        isAvailable ? 'Libre' : 'Ocupado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.publication,
    required this.onActiveChanged,
    required this.onTap,
  });

  final DishPublication publication;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverPhoto = publication.coverPhoto;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child:
                      coverPhoto == null
                          ? const ColoredBox(
                            color: AppTheme.surfaceVariant,
                            child: Icon(Icons.restaurant),
                          )
                          : Image.network(
                            coverPhoto.publicUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const ColoredBox(
                                  color: AppTheme.surfaceVariant,
                                  child: Icon(Icons.broken_image),
                                ),
                          ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            publication.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bs ${publication.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('Cantidad: ${publication.availableQuantity}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(isActive: publication.isActive),
                        const Spacer(),
                        Switch(
                          value: publication.isActive,
                          onChanged: onActiveChanged,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DishPublicationDetailScreen extends StatefulWidget {
  const DishPublicationDetailScreen({
    super.key,
    required this.publication,
    required this.onActiveChanged,
  });

  final DishPublication publication;
  final ValueChanged<bool> onActiveChanged;

  @override
  State<DishPublicationDetailScreen> createState() =>
      _DishPublicationDetailScreenState();
}

class _DishPublicationDetailScreenState
    extends State<DishPublicationDetailScreen> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.publication.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.publication.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.publication.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = widget.publication.photos[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    photo.publicUrl,
                    width: 300,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => const ColoredBox(
                          color: AppTheme.surfaceVariant,
                          child: SizedBox(
                            width: 300,
                            child: Icon(Icons.broken_image),
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.publication.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(isActive: _isActive),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bs ${widget.publication.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(widget.publication.description),
          const SizedBox(height: 14),
          Text('Cantidad disponible: ${widget.publication.availableQuantity}'),
          if (widget.publication.zoneLabel != null)
            Text('Zona: ${widget.publication.zoneLabel}'),
          const SizedBox(height: 22),
          SwitchListTile(
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value);
              widget.onActiveChanged(value);
            },
            title: const Text('Plato activo'),
            subtitle: const Text(
              'Activalo cuando tengas ingredientes y puedas prepararlo.',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.success : AppTheme.warning;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          isActive ? 'Activo' : 'Pausado',
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyPublicationsCard extends StatelessWidget {
  const _EmptyPublicationsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('Aun no tienes platos publicados.'),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.error)),
    );
  }
}
