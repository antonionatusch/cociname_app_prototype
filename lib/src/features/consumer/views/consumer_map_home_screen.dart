import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  final _queryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _radiusController = TextEditingController();
  bool _showSearchPanel = false;

  @override
  void dispose() {
    _mapController.dispose();
    _queryController.dispose();
    _budgetController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConsumerMapHomeViewModel>();

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
              if (vm.showMarkers)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: vm.currentLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
                    ),
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
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          _TopBar(onSearchTap: () => setState(() => _showSearchPanel = true)),
          if (_showSearchPanel) _SearchPanel(vm: vm),
          _BottomPanel(
            vm: vm,
            onSearch: () => setState(() => _showSearchPanel = !_showSearchPanel),
          ),
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

  void _showCookInfo(BuildContext context, ConsumerMapHomeViewModel vm, String cookId) {
    vm.onCookTapped(cookId);
    final cookName = vm.getSelectedCookName() ?? 'Cocinero';

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange, size: 32),
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
                      const Text('Disponible', style: TextStyle(color: Colors.green)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
  const _SearchPanel({required this.vm});

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  final _queryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _radiusController = TextEditingController(text: '4');
  bool _isCreating = false;

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
        onTap: () => Navigator.of(context).pop(),
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
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                            FilterChip(label: const Text('Sin gluten'), onSelected: (_) {}),
                            FilterChip(label: const Text('Sin lácteos'), onSelected: (_) {}),
                            FilterChip(label: const Text('Sin huevo'), onSelected: (_) {}),
                            FilterChip(label: const Text('Sin maní'), onSelected: (_) {}),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(widget.vm.searchStatus),
                              ],
                            ),
                          ),
                        if (widget.vm.searchStatus.isNotEmpty && !widget.vm.isSearching)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(widget.vm.searchStatus)),
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

    if (query.isEmpty) return;
    final budget = double.tryParse(budgetText);
    final radius = double.tryParse(radiusText) ?? 4;
    if (budget == null || budget <= 0) return;

    setState(() => _isCreating = true);

    await widget.vm.createSearchRequest(
      query: query,
      budget: budget,
      maxRadius: radius,
    );

    if (mounted) setState(() => _isCreating = false);
  }
}

class _BottomPanel extends StatelessWidget {
  final ConsumerMapHomeViewModel vm;
  final VoidCallback onSearch;

  const _BottomPanel({
    required this.vm,
    required this.onSearch,
  });

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
              _DefaultChips(onSearch: onSearch, vm: vm),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bs. ${offer.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (offer.estimatedMinutes != null)
                              Text(
                                '${offer.estimatedMinutes} min',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            if (offer.message.isNotEmpty)
                              Text(
                                offer.message,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
          builder: (_) => ActiveOrderScreen(
            order: order,
            dishLabel: 'Plato solicitado',
          ),
        ),
      );
    }
  }
}

class _DefaultChips extends StatelessWidget {
  final VoidCallback onSearch;
  final ConsumerMapHomeViewModel vm;

  const _DefaultChips({required this.onSearch, required this.vm});

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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  icon: Icons.local_pizza,
                  label: 'Pizza',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  icon: Icons.lunch_dining,
                  label: 'Hamburguesa',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickChip(
                  icon: Icons.cookie,
                  label: 'Cuñapé',
                  onTap: () {},
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
