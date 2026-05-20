import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../orders/models/order.dart';

class ActiveOrderScreen extends StatelessWidget {
  final Order order;
  final String consumerLabel;
  final String cookLabel;
  final String dishLabel;

  const ActiveOrderScreen({
    super.key,
    required this.order,
    this.consumerLabel = 'Consumidor',
    this.cookLabel = 'Emprendedor',
    this.dishLabel = 'Plato',
  });

  @override
  Widget build(BuildContext context) {
    final center =
        order.hasPublicationLocation
            ? latlong.LatLng(
              order.publicationLatitude!,
              order.publicationLongitude!,
            )
            : order.hasConsumerLocation
            ? latlong.LatLng(order.consumerLatitude!, order.consumerLongitude!)
            : const latlong.LatLng(-17.7833, -63.1821);
    final resolvedDishLabel = order.dishTitle ?? dishLabel;
    final resolvedCookLabel = order.cookBusinessName ?? cookLabel;
    final resolvedConsumerLabel = order.consumerDisplayName ?? consumerLabel;

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
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 36,
                        ),
                      ),
                    if (order.hasPublicationLocation)
                      Marker(
                        point: latlong.LatLng(
                          order.publicationLatitude!,
                          order.publicationLongitude!,
                        ),
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.deepOrange,
                          size: 34,
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
                _InfoRow(label: 'Plato', value: resolvedDishLabel),
                _InfoRow(
                  label: 'Precio acordado',
                  value: 'Bs. ${order.agreedPrice.toStringAsFixed(2)}',
                ),
                _InfoRow(label: 'Cocinero', value: resolvedCookLabel),
                _InfoRow(label: 'Consumidor', value: resolvedConsumerLabel),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
