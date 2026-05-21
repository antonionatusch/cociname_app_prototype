import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';

import '../../../core/services/permission_service.dart';
import '../../offers/repositories/offer_repository.dart';
import '../../orders/repositories/order_repository.dart';
import '../../orders/views/active_order_screen.dart';
import '../repositories/consumer_request_repository.dart';
import '../viewmodels/consumer_map_home_viewmodel.dart';

class ConsumerMapHomeScreen extends StatelessWidget {
  const ConsumerMapHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = ConsumerMapHomeViewModel(
          permissionService: context.read<PermissionService>(),
          requestRepository: context.read<ConsumerRequestRepository>(),
          offerRepository: context.read<OfferRepository>(),
          orderRepository: context.read<OrderRepository>(),
        );
        vm.init();
        return vm;
      },
      child: const _ConsumerMapView(),
    );
  }
}

class _ConsumerMapView extends StatefulWidget {
  const _ConsumerMapView();

  @override
  State<_ConsumerMapView> createState() => _ConsumerMapViewState();
}

class _ConsumerMapViewState extends State<_ConsumerMapView> {
  final _mapController = MapController();
  bool _showSearchPanel = false;
  String? _searchInitialQuery;
  bool _openingActiveOrder = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConsumerMapHomeViewModel>();
    final offerLocations =
        vm.receivedOffers
            .where((offer) => offer.hasPublicationLocation)
            .toList();
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
                      (_) => const ConsumerMapHomeScreen(),
                ),
          ),
        );
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: vm.currentLatLng,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cociname.app',
              ),
              if (vm.showMarkers || offerLocations.isNotEmpty)
                MarkerLayer(
                  markers: [
                    if (vm.showMarkers)
                      Marker(
                        point: vm.currentLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                    if (vm.showMarkers)
                      ...vm.cooks.map(
                        (cook) => Marker(
                          point: cook.latLng,
                          width: 60,
                          height: 60,
                          child: GestureDetector(
                            onTap: () => _showCookInfo(context, vm, cook.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ...offerLocations.map(
                      (offer) => Marker(
                        point: latlong.LatLng(
                          offer.publicationLatitude!,
                          offer.publicationLongitude!,
                        ),
                        width: 64,
                        height: 64,
                        child: Tooltip(
                          message: offer.cookBusinessName ?? 'Oferta recibida',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_dining,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          _TopBar(onSearchTap: () => _openSearchPanel()),
          if (_showSearchPanel)
            _SearchPanel(
              vm: vm,
              initialQuery: _searchInitialQuery,
              onClose: () => setState(() => _showSearchPanel = false),
            ),
          _BottomPanel(vm: vm, onQuickSearch: _openSearchPanel),
          if (vm.isLoadingLocation)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openSearchPanel([String? query]) {
    setState(() {
      _searchInitialQuery = query;
      _showSearchPanel = true;
    });
  }

  void _showCookInfo(
    BuildContext context,
    ConsumerMapHomeViewModel vm,
    String cookId,
  ) {
    vm.onCookTapped(cookId);
    final cookName = vm.getSelectedCookName() ?? 'Cocinero';

    showModalBottomSheet(
      context: context,
      builder:
          (sheetContext) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      color: Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cookName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Disponible',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Platos activos: 3'),
                const Text('Distancia aprox: 0.8 km'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Ver platos'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  const _TopBar({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSearchTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 8),
                    Text('¿Qué quieres comer?'),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.filter_list, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatefulWidget {
  final ConsumerMapHomeViewModel vm;
  final String? initialQuery;
  final VoidCallback onClose;

  const _SearchPanel({
    required this.vm,
    required this.initialQuery,
    required this.onClose,
  });

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  final _queryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _radiusController = TextEditingController(text: '4');
  bool _isCreating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _queryController.text = widget.initialQuery ?? '';
  }

  @override
  void didUpdateWidget(covariant _SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      _queryController.text = widget.initialQuery ?? '';
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _budgetController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black26,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {},
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '¿Qué quieres comer?',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _queryController,
                          decoration: const InputDecoration(
                            labelText: 'Plato',
                            hintText: 'Ej.: empanada, pizza',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _budgetController,
                          decoration: const InputDecoration(
                            labelText: 'Presupuesto (Bs.)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monetization_on),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _radiusController,
                          decoration: const InputDecoration(
                            labelText: 'Radio máximo (km)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.radio_button_checked),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Restricciones',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Sin gluten'),
                              onSelected: (_) {},
                            ),
                            FilterChip(
                              label: const Text('Sin lácteos'),
                              onSelected: (_) {},
                            ),
                            FilterChip(
                              label: const Text('Sin huevo'),
                              onSelected: (_) {},
                            ),
                            FilterChip(
                              label: const Text('Sin maní'),
                              onSelected: (_) {},
                            ),
                          ],
                        ),
                        if (_isCreating || widget.vm.isSearching)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(widget.vm.searchStatus),
                              ],
                            ),
                          ),
                        if (widget.vm.searchStatus.isNotEmpty &&
                            !widget.vm.isSearching)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(widget.vm.searchStatus)),
                              ],
                            ),
                          ),
                        if (_validationError != null || widget.vm.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _validationError ?? widget.vm.error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isCreating ? null : _createRequest,
                            icon: const Icon(Icons.search),
                            label: const Text('Buscar plato'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createRequest() async {
    final query = _queryController.text.trim();
    final budgetText = _budgetController.text.trim();
    final radiusText = _radiusController.text.trim();

    if (query.isEmpty) {
      setState(() => _validationError = 'Ingresa el plato que quieres buscar.');
      return;
    }
    final budget = double.tryParse(budgetText);
    final radius = double.tryParse(radiusText) ?? 4;
    if (budget == null || budget <= 0) {
      setState(() => _validationError = 'Ingresa un presupuesto mayor a 0.');
      return;
    }

    setState(() {
      _validationError = null;
      _isCreating = true;
    });

    final requestId = await widget.vm.createSearchRequest(
      query: query,
      budget: budget,
      maxRadius: radius,
    );

    if (mounted) setState(() => _isCreating = false);
    if (requestId != null && mounted) widget.onClose();
  }
}

class _BottomPanel extends StatelessWidget {
  final ConsumerMapHomeViewModel vm;
  final ValueChanged<String> onQuickSearch;

  const _BottomPanel({required this.vm, required this.onQuickSearch});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.hasOffers)
              _OffersList(vm: vm)
            else if (vm.activeRequestId != null)
              _SearchingStatus(vm: vm)
            else
              _DefaultChips(onQuickSearch: onQuickSearch, vm: vm),
          ],
        ),
      ),
    );
  }
}

class _SearchingStatus extends StatelessWidget {
  final ConsumerMapHomeViewModel vm;
  const _SearchingStatus({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(vm.searchStatus)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => vm.cancelSearch(),
            child: const Text('Cancelar búsqueda'),
          ),
        ),
      ],
    );
  }
}

class _OffersList extends StatelessWidget {
  final ConsumerMapHomeViewModel vm;
  const _OffersList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final offers = vm.receivedOffers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ofertas recibidas (${offers.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (offer.dishPhotoPublicUrl != null &&
                          offer.dishPhotoPublicUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            offer.dishPhotoPublicUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.orange[50],
                                  child: const Icon(Icons.restaurant),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.dishTitle ?? 'Oferta de plato',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.storefront,
                                  size: 14,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    offer.cookBusinessName ??
                                        'Cocinero disponible',
                                    style: TextStyle(color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Bs. ${offer.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (offer.estimatedMinutes != null)
                                  Text(
                                    '${offer.estimatedMinutes} min',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                if (offer.distanceKm != null)
                                  Text(
                                    '${offer.distanceKm!.toStringAsFixed(1)} km',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                if (offer.cookRatingAverage != null)
                                  Text(
                                    '${offer.cookRatingAverage!.toStringAsFixed(1)} ★',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            if (offer.allergenCodes.isNotEmpty)
                              Text(
                                'Alergenos: ${offer.allergenCodes.join(', ')}',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (offer.message.isNotEmpty)
                              Text(
                                offer.message,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _acceptOffer(context, offer.id),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => vm.cancelSearch(),
            child: const Text('Cancelar búsqueda'),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptOffer(BuildContext context, String offerId) async {
    final vm = this.vm;
    final order = await vm.acceptOffer(offerId);
    if (order != null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => ActiveOrderScreen(
                order: order,
                dishLabel: 'Plato solicitado',
                cancelledDestinationBuilder:
                    (_) => const ConsumerMapHomeScreen(),
              ),
        ),
      );
    }
  }
}

class _DefaultChips extends StatelessWidget {
  final ValueChanged<String> onQuickSearch;
  final ConsumerMapHomeViewModel vm;

  const _DefaultChips({required this.onQuickSearch, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cocineros cerca',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (vm.showMarkers)
              Text(
                '${vm.cooks.length} disponibles',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: _QuickChip(
                  icon: Icons.egg,
                  label: 'Empanada',
                  onTap: () => onQuickSearch('empanada'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  icon: Icons.local_pizza,
                  label: 'Pizza',
                  onTap: () => onQuickSearch('pizza'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  icon: Icons.lunch_dining,
                  label: 'Hamburguesa',
                  onTap: () => onQuickSearch('hamburguesa'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  icon: Icons.cookie,
                  label: 'Cuñapé',
                  onTap: () => onQuickSearch('cuñapé'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.orange[700]),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
