import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_session_viewmodel.dart';
import '../../consumer/models/consumer_request.dart';
import '../../consumer/repositories/consumer_request_repository.dart';
import '../../consumer/views/consumer_map_home_screen.dart';
import '../../orders/repositories/order_repository.dart';
import '../../orders/views/active_order_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key, required this.sessionViewModel});

  final AppSessionViewModel sessionViewModel;

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  bool _checkingActiveOrder = true;
  bool _openingActiveOrder = false;
  bool _loadingRecentRequests = true;
  List<ConsumerRequest> _recentRequests = const [];
  String? _recentRequestsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  Future<void> _loadHomeData() async {
    await _checkActiveOrder();
    if (!mounted || _openingActiveOrder) return;
    await _loadRecentRequests();
  }

  Future<void> _checkActiveOrder() async {
    try {
      final order = await context.read<OrderRepository>().fetchActiveOrder();
      if (!mounted) return;

      if (order != null) {
        _openingActiveOrder = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => ActiveOrderScreen(
                  order: order,
                  cancelledDestinationBuilder:
                      (_) => ConsumerHomeScreen(
                        sessionViewModel: widget.sessionViewModel,
                      ),
                ),
          ),
        );
        return;
      }
    } catch (_) {}

    if (!mounted || _openingActiveOrder) return;
    setState(() => _checkingActiveOrder = false);
  }

  Future<void> _loadRecentRequests() async {
    if (!mounted || _openingActiveOrder) return;

    setState(() {
      _loadingRecentRequests = true;
      _recentRequestsError = null;
    });

    try {
      final requests =
          await context.read<ConsumerRequestRepository>().fetchRecentRequests();
      if (!mounted || _openingActiveOrder) return;
      setState(() {
        _recentRequests = requests;
        _loadingRecentRequests = false;
      });
    } catch (_) {
      if (!mounted || _openingActiveOrder) return;
      setState(() {
        _recentRequestsError = 'No se pudieron cargar tus solicitudes.';
        _loadingRecentRequests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CocinaME'),
        actions: [
          IconButton(
            onPressed: widget.sessionViewModel.signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (_checkingActiveOrder) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
          ],
          Text(
            'Hola, ${widget.sessionViewModel.displayName}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué se te antoja hoy?',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConsumerMapHomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Buscar comida en el mapa'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Text('Mapa', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConsumerMapHomeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimas solicitudes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RecentRequestsSection(
            isLoading: _loadingRecentRequests,
            requests: _recentRequests,
            error: _recentRequestsError,
            onRetry: _loadRecentRequests,
            onOpenMap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConsumerMapHomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentRequestsSection extends StatelessWidget {
  final bool isLoading;
  final List<ConsumerRequest> requests;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onOpenMap;

  const _RecentRequestsSection({
    required this.isLoading,
    required this.requests,
    required this.error,
    required this.onRetry,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Cargando solicitudes...'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error!, style: TextStyle(color: Colors.red[700])),
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (requests.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'Aún no has realizado ninguna búsqueda',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children:
          requests
              .map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentRequestCard(
                    request: request,
                    onOpenMap: onOpenMap,
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _RecentRequestCard extends StatelessWidget {
  final ConsumerRequest request;
  final VoidCallback onOpenMap;

  const _RecentRequestCard({required this.request, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    final canOpenMap =
        request.status == 'searching' || request.status == 'matched';
    final acceptedCook = request.acceptedCookBusinessName;
    final acceptedDish = request.acceptedDishTitle;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canOpenMap ? onOpenMap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.queryText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RequestStatusChip(request: request),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RequestInfoChip(
                    label:
                        'Presupuesto: Bs. ${request.targetPrice.toStringAsFixed(0)}',
                  ),
                  _RequestInfoChip(
                    label: 'Cantidad: ${request.requestedQuantity}',
                  ),
                  if (request.offerCount > 0)
                    _RequestInfoChip(label: '${request.offerCount} oferta(s)'),
                  if (request.allergenFilters.isNotEmpty)
                    _RequestInfoChip(
                      label: '${request.allergenFilters.length} alergia(s)',
                    ),
                ],
              ),
              if (acceptedCook != null && acceptedCook.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.storefront, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cocinero: ${acceptedCook.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (acceptedDish != null && acceptedDish.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Plato acordado: ${acceptedDish.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Creada: ${_formatRequestDate(request.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestStatusChip extends StatelessWidget {
  final ConsumerRequest request;

  const _RequestStatusChip({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = _requestStatusColor(request, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _requestStatusLabel(request),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequestInfoChip extends StatelessWidget {
  final String label;

  const _RequestInfoChip({required this.label});

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

String _requestStatusLabel(ConsumerRequest request) {
  if (request.completedAt != null) return 'Completada';

  return switch (request.status) {
    'searching' => 'Buscando',
    'matched' => 'Pedido activo',
    'cancelled' => 'Cancelada',
    'expired' => 'Finalizada',
    _ => request.status,
  };
}

Color _requestStatusColor(ConsumerRequest request, BuildContext context) {
  if (request.completedAt != null) return Colors.green[700]!;

  return switch (request.status) {
    'searching' => Theme.of(context).colorScheme.primary,
    'matched' => Colors.blue[700]!,
    'cancelled' => Colors.red[700]!,
    'expired' => Colors.grey[700]!,
    _ => Colors.grey[700]!,
  };
}

String _formatRequestDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
