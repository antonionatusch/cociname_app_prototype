import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';

class ActiveOrderScreen extends StatefulWidget {
  final Order order;
  final String consumerLabel;
  final String cookLabel;
  final String dishLabel;
  final WidgetBuilder? cancelledDestinationBuilder;

  const ActiveOrderScreen({
    super.key,
    required this.order,
    this.consumerLabel = 'Consumidor',
    this.cookLabel = 'Emprendedor',
    this.dishLabel = 'Plato',
    this.cancelledDestinationBuilder,
  });

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  bool _isCancelling = false;
  String? _error;

  Future<void> _confirmCancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cancelar pedido'),
            content: const Text(
              '¿Quieres cancelar este pedido? Ambos participantes dejarán de verlo como pedido activo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Cancelar pedido'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isCancelling = true;
      _error = null;
    });

    try {
      await context.read<OrderRepository>().cancelOrder(widget.order.id);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pedido cancelado')));

      final cancelledDestinationBuilder = widget.cancelledDestinationBuilder;
      if (cancelledDestinationBuilder != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: cancelledDestinationBuilder),
        );
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isCancelling = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCancelling = false;
        _error = 'No se pudo cancelar el pedido: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final center =
        order.hasPublicationLocation
            ? latlong.LatLng(
              order.publicationLatitude!,
              order.publicationLongitude!,
            )
            : order.hasConsumerLocation
            ? latlong.LatLng(order.consumerLatitude!, order.consumerLongitude!)
            : const latlong.LatLng(-17.7833, -63.1821);
    final resolvedDishLabel = order.dishTitle ?? widget.dishLabel;
    final resolvedCookLabel = order.cookBusinessName ?? widget.cookLabel;
    final resolvedConsumerLabel =
        order.consumerDisplayName ?? widget.consumerLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido en curso'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 14.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cociname.app',
                ),
                MarkerLayer(
                  markers: [
                    if (order.hasConsumerLocation)
                      Marker(
                        point: latlong.LatLng(
                          order.consumerLatitude!,
                          order.consumerLongitude!,
                        ),
                        width: 82,
                        height: 64,
                        child: const _MapMarkerBadge(
                          icon: Icons.person,
                          color: Colors.blue,
                          label: 'Consumidor',
                        ),
                      ),
                    if (order.hasPublicationLocation)
                      Marker(
                        point: latlong.LatLng(
                          order.publicationLatitude!,
                          order.publicationLongitude!,
                        ),
                        width: 72,
                        height: 64,
                        child: const _MapMarkerBadge(
                          icon: Icons.restaurant,
                          color: Colors.deepOrange,
                          label: 'Cocinero',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pedido en curso',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.restaurant_menu,
                  label: 'Plato',
                  value: resolvedDishLabel,
                ),
                _InfoRow(
                  icon: Icons.payments,
                  label: 'Precio acordado',
                  value: 'Bs. ${order.agreedPrice.toStringAsFixed(2)}',
                ),
                _InfoRow(
                  icon: Icons.storefront,
                  label: 'Cocinero',
                  value: resolvedCookLabel,
                ),
                _InfoRow(
                  icon: Icons.person,
                  label: 'Consumidor',
                  value: resolvedConsumerLabel,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Abrir navegación'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Contactar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isCancelling ? null : _confirmCancelOrder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                    icon:
                        _isCancelling
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      _isCancelling ? 'Cancelando...' : 'Cancelar pedido',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarkerBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MapMarkerBadge({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _InfoRow({this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.deepOrange),
            const SizedBox(width: 8),
          ],
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
