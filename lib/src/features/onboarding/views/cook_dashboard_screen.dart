import 'package:flutter/material.dart';
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
import '../../offers/views/create_offer_sheet.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= CookDashboardViewModel(
      publicationRepository: context.read<DishPublicationRepository>(),
      cookRequestRepository: context.read<CookRequestRepository>(),
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
    final captureResult = await Navigator.of(context).push<InferenceCaptureResult>(
      MaterialPageRoute(
        builder: (_) => const DishInferenceCaptureScreen(),
      ),
    );

    if (captureResult == null) return;
    if (!context.mounted) return;

    // Step 2: Fill publication details
    final publishResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create:
                  (_) {
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
        const SnackBar(content: Text('Plato publicado exitosamente')),
      );
      await _viewModel?.load();
    }
  }

  Future<DishPublication?> _editPublication(
    BuildContext context,
    CookDashboardViewModel vm,
    DishPublication publication,
  ) async {
    final updated = await showDialog<DishPublication>(
      context: context,
      builder:
          (dialogContext) => _EditPublicationDialog(
            publication: publication,
            onSave: ({
              required title,
              required description,
              required price,
              required availableQuantity,
              latitude,
              longitude,
              zoneLabel,
            }) async {
              final success = await vm.updatePublication(
                publicationId: publication.id,
                title: title,
                description: description,
                price: price,
                availableQuantity: availableQuantity,
                latitude: latitude,
                longitude: longitude,
                zoneLabel: zoneLabel,
              );
              if (!success) return null;
              return publication.copyWith(
                title: title,
                description: description,
                price: price,
                availableQuantity: availableQuantity,
                latitude: latitude,
                longitude: longitude,
                zoneLabel: zoneLabel,
              );
            },
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
                      ),
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

  const _IncomingRequestCard({
    required this.request,
    required this.publications,
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
            Row(
              children: [
                _InfoChip(label: 'Bs. ${request.targetPrice.toStringAsFixed(0)}'),
                const SizedBox(width: 8),
                _InfoChip(label: '${request.maxRadiusKm.toStringAsFixed(0)} km'),
                if (request.allergenFilters.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _InfoChip(label: request.allergenFilters.join(', ')),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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

  void _showOfferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (sheetContext) => CreateOfferSheet(
            request: request,
            publications: publications,
          ),
    );
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
        padding: const EdgeInsets.all(20),
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
            'Bs ${_publication.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(_publication.description),
          const SizedBox(height: 14),
          Text('Cantidad disponible: ${_publication.availableQuantity}'),
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
        child: Text('Aun no tienes platos publicados.'),
      ),
    );
  }
}

typedef _SavePublicationEdit = Future<DishPublication?> Function({
  required String title,
  required String description,
  required double price,
  required int availableQuantity,
  double? latitude,
  double? longitude,
  String? zoneLabel,
});

class _EditPublicationDialog extends StatefulWidget {
  const _EditPublicationDialog({
    required this.publication,
    required this.onSave,
  });

  final DishPublication publication;
  final _SavePublicationEdit onSave;

  @override
  State<_EditPublicationDialog> createState() => _EditPublicationDialogState();
}

class _EditPublicationDialogState extends State<_EditPublicationDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  double? _latitude;
  double? _longitude;
  String? _zoneLabel;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.publication.title);
    _descriptionController = TextEditingController(
      text: widget.publication.description,
    );
    _priceController = TextEditingController(
      text: widget.publication.price.toStringAsFixed(2),
    );
    _quantityController = TextEditingController(
      text: widget.publication.availableQuantity.toString(),
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

    return AlertDialog(
      title: const Text('Modificar publicación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Nombre del plato'),
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
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
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
                        : (widget.publication.zoneLabel ?? 'Sin ubicación'),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Guardar'),
        ),
      ],
    );
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

    final updated = await widget.onSave(
      title: title,
      description: description,
      price: price,
      availableQuantity: quantity,
      latitude: _latitude,
      longitude: _longitude,
      zoneLabel: _zoneLabel,
    );

    if (!mounted) return;
    if (updated == null) {
      setState(() {
        _isSaving = false;
        _error = 'No se pudo guardar la publicación';
      });
      return;
    }

    Navigator.of(context).pop(updated);
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
