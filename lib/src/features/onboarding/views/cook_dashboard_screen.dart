import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/app_session_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../consumer/models/consumer_request.dart';
import '../../dish_inference/models/inference_capture_result.dart';
import '../../dish_inference/views/dish_inference_capture_screen.dart';
import '../../dish_publication/models/dish_publication.dart';
import '../../dish_publication/repositories/dish_publication_repository.dart';
import '../../dish_publication/repositories/ingredient_repository.dart';
import '../../dish_publication/services/location_service.dart';
import '../../dish_publication/services/tflite_vision_classifier_service.dart';
import '../../dish_publication/viewmodels/publish_dish_viewmodel.dart';
import '../../dish_publication/views/publish_dish_screen.dart';
import '../../maps/views/location_picker_screen.dart';
import '../../offers/models/cook_active_offer.dart';
import '../../offers/repositories/offer_repository.dart';
import '../../offers/views/create_offer_sheet.dart';
import '../../orders/repositories/order_repository.dart';
import '../../../core/helpers/allergen_display_helper.dart';
import '../../orders/views/active_order_screen.dart';
import '../repositories/cook_request_repository.dart';
import '../viewmodels/cook_dashboard_viewmodel.dart';

class CookDashboardScreen extends StatefulWidget {
  const CookDashboardScreen({super.key, required this.sessionViewModel});

  final AppSessionViewModel sessionViewModel;

  @override
  State<CookDashboardScreen> createState() => _CookDashboardScreenState();
}

class _CookDashboardScreenState extends State<CookDashboardScreen> {
  CookDashboardViewModel? _viewModel;
  bool _openingActiveOrder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= CookDashboardViewModel(
      publicationRepository: context.read<DishPublicationRepository>(),
      cookRequestRepository: context.read<CookRequestRepository>(),
      orderRepository: context.read<OrderRepository>(),
      offerRepository: context.read<OfferRepository>(),
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

    // Step 1: Capture photo and run inference
    final captureResult = await Navigator.of(
      context,
    ).push<InferenceCaptureResult>(
      MaterialPageRoute(builder: (_) => const DishInferenceCaptureScreen()),
    );

    if (captureResult == null) return;
    if (!context.mounted) return;

    // Step 2: Fill publication details
    final publishResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (_) {
                final vm = PublishDishViewModel(
                  classifier: classifier,
                  locationService: locationService,
                  publicationRepository: publicationRepo,
                  ingredientRepository: ingredientRepo,
                );
                vm.initializeWithInference(
                  captureResult.imageFile,
                  captureResult.inferenceResult,
                );
                return vm;
              },
              child: const PublishDishScreen(),
            ),
      ),
    );

    if (!context.mounted) return;

    if (publishResult == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plato publicado con éxito')),
      );
      await _viewModel?.load();
    }
  }

  Future<DishPublication?> _editPublication(
    BuildContext context,
    CookDashboardViewModel vm,
    DishPublication publication,
  ) async {
    final updated = await Navigator.of(context).push<DishPublication>(
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider.value(
              value: vm,
              child: _EditPublicationScreen(publication: publication),
            ),
      ),
    );

    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación actualizada')));
    }
    return updated;
  }

  Future<bool> _deletePublication(
    BuildContext context,
    CookDashboardViewModel vm,
    DishPublication publication,
  ) async {
    if (publication.isActive) {
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Pausa la publicación primero'),
              content: const Text(
                'Antes de borrar esta publicación debes desactivarla. Esto evita eliminar un plato que todavía puede recibir solicitudes.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Borrar publicación'),
            content: Text(
              '¿Quieres borrar "${publication.title}"? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Borrar'),
              ),
            ],
          ),
    );

    if (confirmed != true) return false;

    final deleted = await vm.deletePublication(publication);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación eliminada')));
    }
    return deleted;
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
              tooltip: 'Cerrar sesión',
            ),
          ],
        ),
        body: Consumer<CookDashboardViewModel>(
          builder: (context, vm, _) {
            final activeOrder = vm.activeOrder;
            if (activeOrder != null && !_openingActiveOrder) {
              _openingActiveOrder = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (_) => ActiveOrderScreen(
                          order: activeOrder,
                          cancelledDestinationBuilder:
                              (_) => CookDashboardScreen(
                                sessionViewModel: widget.sessionViewModel,
                              ),
                        ),
                  ),
                );
              });
            }

            return RefreshIndicator(
              onRefresh: vm.load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  28 + MediaQuery.of(context).viewPadding.bottom,
                ),
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
                  if (vm.hasIncomingRequests) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Solicitudes entrantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...vm.incomingRequests.map(
                      (request) => _IncomingRequestCard(
                        request: request,
                        publications: vm.publications,
                        onIgnore: () => vm.ignoreRequest(request.id),
                        onOfferCreated: vm.refreshActiveOffers,
                      ),
                    ),
                  ],
                  if (vm.activeOffers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Ofertas enviadas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...vm.activeOffers.map(
                      (offer) => _ActiveOfferCard(offer: offer),
                    ),
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
                        onEdit:
                            () => _editPublication(context, vm, publication),
                        onDelete:
                            () => _deletePublication(context, vm, publication),
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
                                      onEdit:
                                          (current) => _editPublication(
                                            context,
                                            vm,
                                            current,
                                          ),
                                      onDelete:
                                          (current) => _deletePublication(
                                            context,
                                            vm,
                                            current,
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

class _IncomingRequestCard extends StatelessWidget {
  final ConsumerRequest request;
  final List<DishPublication> publications;
  final VoidCallback onIgnore;
  final VoidCallback? onOfferCreated;

  const _IncomingRequestCard({
    required this.request,
    required this.publications,
    required this.onIgnore,
    this.onOfferCreated,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Busca: ${request.queryText}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label:
                      'Presupuesto total: Bs. ${request.targetPrice.toStringAsFixed(0)}',
                ),
                _InfoChip(label: 'Cantidad: ${request.requestedQuantity}'),
                _InfoChip(
                  label: '${request.maxRadiusKm.toStringAsFixed(0)} km',
                ),
                if (request.allergenFilters.isNotEmpty)
                  _InfoChip(
                    label:
                        'Alérgico a: ${formatAllergenFilters(request.allergenFilters)}',
                  )
                else
                  _InfoChip(label: 'Sin alergias declaradas'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onIgnore, child: const Text('Ignorar')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _showOfferSheet(context),
                  child: const Text('Ofertar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOfferSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder:
          (sheetContext) =>
              CreateOfferSheet(request: request, publications: publications),
    );
    if (created == true) {
      onIgnore();
      onOfferCreated?.call();
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
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
                        ? 'Estás libre para recibir oportunidades.'
                        : 'Estás ocupado; pausaremos nuevas oportunidades.',
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

enum _PublicationAction { edit, delete }

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.publication,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  final DishPublication publication;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
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
                        PopupMenuButton<_PublicationAction>(
                          onSelected: (action) {
                            switch (action) {
                              case _PublicationAction.edit:
                                onEdit();
                              case _PublicationAction.delete:
                                onDelete();
                            }
                          },
                          itemBuilder:
                              (context) => const [
                                PopupMenuItem(
                                  value: _PublicationAction.edit,
                                  child: Text('Modificar'),
                                ),
                                PopupMenuItem(
                                  value: _PublicationAction.delete,
                                  child: Text('Borrar'),
                                ),
                              ],
                        ),
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
                    Text(
                      'Cantidad disponible: ${publication.availableQuantity}',
                    ),
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
    required this.onEdit,
    required this.onDelete,
  });

  final DishPublication publication;
  final ValueChanged<bool> onActiveChanged;
  final Future<DishPublication?> Function(DishPublication publication) onEdit;
  final Future<bool> Function(DishPublication publication) onDelete;

  @override
  State<DishPublicationDetailScreen> createState() =>
      _DishPublicationDetailScreenState();
}

class _DishPublicationDetailScreenState
    extends State<DishPublicationDetailScreen> {
  late bool _isActive;
  late DishPublication _publication;

  @override
  void initState() {
    super.initState();
    _publication = widget.publication;
    _isActive = _publication.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 20 + MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(_publication.title),
        actions: [
          IconButton(
            onPressed: () async {
              final updated = await widget.onEdit(_publication);
              if (updated != null && mounted) {
                setState(
                  () => _publication = updated.copyWith(isActive: _isActive),
                );
              }
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Modificar',
          ),
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final deleted = await widget.onDelete(
                _publication.copyWith(isActive: _isActive),
              );
              if (deleted && mounted) {
                navigator.pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Borrar',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
        children: [
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _publication.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = _publication.photos[index];
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
                  _publication.title,
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
            'Bs ${_publication.price.toStringAsFixed(2)} por unidad',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(_publication.description),
          const SizedBox(height: 14),
          Text('Cantidad disponible: ${_publication.availableQuantity}'),
          Text(
            'Rating del plato: ${_publication.ratingAverage.toStringAsFixed(1)} ★ (${_publication.ratingCount})',
          ),
          if (_publication.zoneLabel != null)
            Text('Zona: ${_publication.zoneLabel}'),
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
        child: Text('Aún no tienes platos publicados.'),
      ),
    );
  }
}

class _EditPublicationScreen extends StatefulWidget {
  const _EditPublicationScreen({required this.publication});

  final DishPublication publication;

  @override
  State<_EditPublicationScreen> createState() => _EditPublicationScreenState();
}

class _EditPublicationScreenState extends State<_EditPublicationScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late DishPublication _publication;
  double? _latitude;
  double? _longitude;
  String? _zoneLabel;
  String? _error;
  bool _isSaving = false;
  bool _isUpdatingPhoto = false;

  @override
  void initState() {
    super.initState();
    _publication = widget.publication;
    _latitude = _publication.latitude;
    _longitude = _publication.longitude;
    _zoneLabel = _publication.zoneLabel;
    _titleController = TextEditingController(text: _publication.title);
    _descriptionController = TextEditingController(
      text: _publication.description,
    );
    _priceController = TextEditingController(
      text: _publication.price.toStringAsFixed(2),
    );
    _quantityController = TextEditingController(
      text: _publication.availableQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _latitude != null && _longitude != null;
    final bottomPadding = 24 + MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Modificar publicación')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
        children: [
          Text(
            'La primera foto será la portada. Las demás aparecerán en el detalle que ve el consumidor.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _EditablePhotosSection(
            publication: _publication,
            isBusy: _isUpdatingPhoto || _isSaving,
            onAddFromCamera: () => _addPhoto(ImageSource.camera),
            onAddFromGallery: () => _addPhoto(ImageSource.gallery),
            onDelete: _deletePhoto,
            onMove: _movePhoto,
          ),
          const SizedBox(height: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del plato',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario (Bs.)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad disponible',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    hasLocation ? Icons.location_on : Icons.location_searching,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasLocation
                          ? _zoneLabel!
                          : (_publication.zoneLabel ?? 'Sin ubicación'),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickLocation,
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.error)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving || _isUpdatingPhoto ? null : _save,
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_publication.photos.length >= 3) {
      setState(
        () => _error = 'Solo puedes tener hasta 3 fotos por publicación.',
      );
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _isUpdatingPhoto = true;
      _error = null;
    });

    final updated = await context
        .read<CookDashboardViewModel>()
        .addPublicationPhoto(
          publication: _publication,
          imageFile: File(picked.path),
        );

    if (!mounted) return;
    setState(() {
      _isUpdatingPhoto = false;
      if (updated != null) {
        _publication = updated;
      } else {
        _error = context.read<CookDashboardViewModel>().error;
      }
    });
  }

  Future<void> _deletePhoto(DishPublicationPhoto photo) async {
    setState(() {
      _isUpdatingPhoto = true;
      _error = null;
    });

    final updated = await context
        .read<CookDashboardViewModel>()
        .deletePublicationPhoto(publication: _publication, photo: photo);

    if (!mounted) return;
    setState(() {
      _isUpdatingPhoto = false;
      if (updated != null) {
        _publication = updated;
      } else {
        _error = context.read<CookDashboardViewModel>().error;
      }
    });
  }

  Future<void> _movePhoto(int oldIndex, int newIndex) async {
    setState(() {
      _isUpdatingPhoto = true;
      _error = null;
    });

    final updated = await context
        .read<CookDashboardViewModel>()
        .reorderPublicationPhotos(
          publication: _publication,
          oldIndex: oldIndex,
          newIndex: newIndex,
        );

    if (!mounted) return;
    setState(() {
      _isUpdatingPhoto = false;
      if (updated != null) {
        _publication = updated;
      } else {
        _error = context.read<CookDashboardViewModel>().error;
      }
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude as double;
        _longitude = result.longitude as double;
        _zoneLabel = result.addressLabel as String;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());

    if (title.isEmpty) {
      setState(() => _error = 'Ingresa el nombre del plato');
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _error = 'El precio debe ser mayor a 0');
      return;
    }
    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'La cantidad debe ser mayor a 0');
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    final success = await context
        .read<CookDashboardViewModel>()
        .updatePublication(
          publicationId: _publication.id,
          title: title,
          description: description,
          price: price,
          availableQuantity: quantity,
          latitude: _latitude,
          longitude: _longitude,
          zoneLabel: _zoneLabel,
        );

    if (!mounted) return;
    if (!success) {
      setState(() {
        _isSaving = false;
        _error = 'No se pudo guardar la publicación';
      });
      return;
    }

    final updated = _publication.copyWith(
      title: title,
      description: description,
      price: price,
      availableQuantity: quantity,
      latitude: _latitude,
      longitude: _longitude,
      zoneLabel: _zoneLabel,
    );

    Navigator.of(context).pop(updated);
  }
}

class _EditablePhotosSection extends StatelessWidget {
  const _EditablePhotosSection({
    required this.publication,
    required this.isBusy,
    required this.onAddFromCamera,
    required this.onAddFromGallery,
    required this.onDelete,
    required this.onMove,
  });

  final DishPublication publication;
  final bool isBusy;
  final VoidCallback onAddFromCamera;
  final VoidCallback onAddFromGallery;
  final ValueChanged<DishPublicationPhoto> onDelete;
  final void Function(int oldIndex, int newIndex) onMove;

  @override
  Widget build(BuildContext context) {
    final canAdd = publication.photos.length < 3 && !isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos de la publicación',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: publication.photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photo = publication.photos[index];
              return SizedBox(
                width: 220,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          photo.publicUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const ColoredBox(
                                color: AppTheme.surfaceVariant,
                                child: Icon(Icons.broken_image),
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _PhotoBadge(
                        label: index == 0 ? 'Portada' : 'Foto ${index + 1}',
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed:
                                isBusy || index == 0
                                    ? null
                                    : () => onMove(index, index - 1),
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Mover a la izquierda',
                          ),
                          const SizedBox(width: 4),
                          IconButton.filledTonal(
                            onPressed:
                                isBusy || index == publication.photos.length - 1
                                    ? null
                                    : () => onMove(index, index + 1),
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Mover a la derecha',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: IconButton.filled(
                        onPressed:
                            isBusy || publication.photos.length <= 1
                                ? null
                                : () => onDelete(photo),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar foto',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAdd ? onAddFromCamera : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAdd ? onAddFromGallery : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${publication.photos.length}/3 fotos',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
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

class _ActiveOfferCard extends StatelessWidget {
  final CookActiveOffer offer;

  const _ActiveOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    offer.consumerDisplayName ?? 'Consumidor',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Bs. ${offer.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (offer.consumerQueryText != null &&
                offer.consumerQueryText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Busca: ${offer.consumerQueryText}'),
              ),
            Text('Plato ofertado: ${offer.dishTitle ?? 'Sin título'}'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'Cantidad: ${offer.requestedQuantity}'),
                _InfoChip(
                  label:
                      'Prep. ${offer.estimatedMinutes ?? '?'} min',
                ),
                if (offer.consumerTargetPrice != null)
                  _InfoChip(
                    label:
                        'Presupuesto: Bs. ${offer.consumerTargetPrice!.toStringAsFixed(0)}',
                  ),
                if (offer.consumerAllergenFilters.isNotEmpty)
                  _InfoChip(
                    label:
                        'Alérgico a: ${formatAllergenFilters(offer.consumerAllergenFilters)}',
                  )
                else
                  _InfoChip(label: 'Sin alergias declaradas'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
