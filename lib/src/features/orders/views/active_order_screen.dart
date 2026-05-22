import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
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
  Timer? _statusPollTimer;
  Timer? _clockTimer;
  late Order _order;
  bool _isCancelling = false;
  bool _isUpdatingPhase = false;
  bool _isUploadingDeliveryPhoto = false;
  bool _isPollingStatus = false;
  bool _isLeavingInactiveOrder = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _startStatusPolling();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollOrderStatus();
    });
  }

  Future<void> _pollOrderStatus() async {
    if (_isCancelling || _isLeavingInactiveOrder || _isPollingStatus) return;

    _isPollingStatus = true;
    try {
      final status = await context.read<OrderRepository>().fetchOrderStatus(
        _order.id,
      );
      if (!mounted || _isCancelling || _isLeavingInactiveOrder) return;

      if (status == null) {
        _leaveInactiveOrder('Pedido cerrado');
      } else if (status != 'active') {
        _leaveInactiveOrder(
          status == 'completed'
              ? 'Pedido completado'
              : 'Pedido cancelado por el otro participante',
        );
      } else {
        final freshOrder =
            await context.read<OrderRepository>().fetchActiveOrder();
        if (freshOrder != null && mounted) {
          setState(() => _order = freshOrder);
        }
      }
    } catch (_) {
    } finally {
      _isPollingStatus = false;
    }
  }

  void _leaveInactiveOrder(String message) {
    if (!mounted || _isLeavingInactiveOrder) return;

    _isLeavingInactiveOrder = true;
    _statusPollTimer?.cancel();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    final cancelledDestinationBuilder = widget.cancelledDestinationBuilder;
    if (cancelledDestinationBuilder != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: cancelledDestinationBuilder),
      );
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isCancelling = false;
        _error = 'Este pedido ya no está activo.';
      });
    }
  }

  Future<void> _refreshOrder() async {
    final freshOrder = await context.read<OrderRepository>().fetchActiveOrder();
    if (freshOrder != null && mounted) setState(() => _order = freshOrder);
  }

  Future<void> _runOrderAction(
    Future<void> Function(OrderRepository) action,
  ) async {
    setState(() {
      _isUpdatingPhase = true;
      _error = null;
    });

    try {
      await action(context.read<OrderRepository>());
      await _refreshOrder();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo actualizar el pedido: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingPhase = false);
    }
  }

  Future<void> _takeDeliveryPhoto() async {
    setState(() {
      _isUploadingDeliveryPhoto = true;
      _error = null;
    });

    try {
      final repository = context.read<OrderRepository>();
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (photo == null) return;
      await repository.uploadDeliveryPhoto(orderId: _order.id, photo: photo);
      await _refreshOrder();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo subir la foto de entrega: $e');
    } finally {
      if (mounted) setState(() => _isUploadingDeliveryPhoto = false);
    }
  }

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
      await context.read<OrderRepository>().cancelOrder(_order.id);
      if (!mounted) return;

      _leaveInactiveOrder('Pedido cancelado');
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
    final order = _order;
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
    final bottomPadding = 20 + MediaQuery.of(context).viewPadding.bottom;

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
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
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
                    Icon(
                      _phaseIcon(order),
                      color: _phaseColor(order),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _phaseTitle(order),
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
                  label: 'Precio acordado total',
                  value: 'Bs. ${order.agreedPrice.toStringAsFixed(2)}',
                ),
                _InfoRow(
                  icon: Icons.format_list_numbered,
                  label: 'Cantidad',
                  value: order.requestedQuantity.toString(),
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
                _InfoRow(
                  icon: Icons.timelapse,
                  label: 'Estado',
                  value: _phaseDescription(order),
                ),
                if (_deadlineFor(order) != null)
                  _InfoRow(
                    icon: Icons.timer,
                    label: 'Tiempo restante',
                    value: _timeRemainingText(_deadlineFor(order)!),
                  ),
                if (order.deliveryPhotoPublicUrl != null &&
                    order.deliveryPhotoPublicUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap:
                        () => _openDeliveryPhotoViewer(
                          order.deliveryPhotoPublicUrl!,
                        ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            order.deliveryPhotoPublicUrl!,
                            height: 96,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  height: 96,
                                  alignment: Alignment.center,
                                  color: Colors.green[50],
                                  child: const Text(
                                    'Foto de entrega registrada',
                                  ),
                                ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ver foto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                _OrderPhaseActions(
                  order: order,
                  isBusy: _isUpdatingPhase,
                  isUploadingPhoto: _isUploadingDeliveryPhoto,
                  onConfirmPreparation:
                      () => _runOrderAction(
                        (repo) => repo.confirmPreparation(order.id),
                      ),
                  onMarkReady:
                      () => _runOrderAction((repo) => repo.markReady(order.id)),
                  onTakeDeliveryPhoto: _takeDeliveryPhoto,
                  onConfirmDelivery:
                      order.hasDeliveryPhoto
                          ? () => _runOrderAction(
                            (repo) => repo.confirmDelivery(order.id),
                          )
                          : null,
                ),
                if (order.status == 'active') const SizedBox(height: 8),
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

  IconData _phaseIcon(Order order) {
    switch (order.orderPhase) {
      case 'awaiting_preparation_confirmation':
        return Icons.hourglass_top;
      case 'preparing':
        return Icons.soup_kitchen;
      case 'ready':
        return Icons.restaurant;
      case 'delivered':
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.delivery_dining;
    }
  }

  Color _phaseColor(Order order) {
    switch (order.orderPhase) {
      case 'awaiting_preparation_confirmation':
        return Colors.amber[800]!;
      case 'preparing':
        return Colors.deepOrange;
      case 'ready':
        return Colors.green[700]!;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _phaseTitle(Order order) {
    switch (order.orderPhase) {
      case 'awaiting_preparation_confirmation':
        return order.isCookViewer
            ? 'Confirma preparación'
            : 'Esperando al cocinero';
      case 'preparing':
        return 'Preparando plato';
      case 'ready':
        return order.isCookViewer
            ? 'Listo para entregar'
            : 'Tu plato está hecho';
      case 'delivered':
      case 'completed':
        return 'Pedido completado';
      case 'cancelled':
        return 'Pedido cancelado';
      default:
        return 'Pedido en curso';
    }
  }

  String _phaseDescription(Order order) {
    switch (order.orderPhase) {
      case 'awaiting_preparation_confirmation':
        return order.isCookViewer
            ? 'Tienes hasta 5 minutos para confirmar que empezarás.'
            : 'El cocinero debe confirmar que empezará a preparar.';
      case 'preparing':
        return order.isCookViewer
            ? 'Prepara el plato y marca Plato hecho al terminar.'
            : 'El cocinero está preparando tu pedido.';
      case 'ready':
        return order.isCookViewer
            ? 'Toma una foto obligatoria y confirma la entrega.'
            : 'El cocinero está por entregar tu pedido.';
      case 'delivered':
      case 'completed':
        return 'Entrega confirmada con evidencia.';
      default:
        return 'Pedido activo.';
    }
  }

  DateTime? _deadlineFor(Order order) {
    switch (order.orderPhase) {
      case 'awaiting_preparation_confirmation':
        return order.preparationConfirmationDeadlineAt;
      case 'preparing':
        return order.preparationDeadlineAt;
      case 'ready':
        return order.deliveryDeadlineAt;
      default:
        return null;
    }
  }

  Duration _serverAdjustedTimeRemaining(DateTime deadline) {
    final serverNow = _order.serverNow;
    final localNow = DateTime.now().toUtc();
    if (serverNow == null) return deadline.toUtc().difference(localNow);
    final offset = localNow.difference(serverNow);
    return deadline.toUtc().difference(localNow) + offset;
  }

  String _timeRemainingText(DateTime deadline) {
    final remaining = _serverAdjustedTimeRemaining(deadline);
    if (remaining.isNegative) return 'Tiempo vencido';
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    if (remaining.inHours > 0) {
      return '${remaining.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _openDeliveryPhotoViewer(String photoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _DeliveryPhotoViewer(photoUrl: photoUrl),
      ),
    );
  }
}

class _DeliveryPhotoViewer extends StatelessWidget {
  final String photoUrl;

  const _DeliveryPhotoViewer({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto de entrega'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            photoUrl,
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudo cargar la foto de entrega.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _OrderPhaseActions extends StatelessWidget {
  final Order order;
  final bool isBusy;
  final bool isUploadingPhoto;
  final VoidCallback onConfirmPreparation;
  final VoidCallback onMarkReady;
  final VoidCallback onTakeDeliveryPhoto;
  final VoidCallback? onConfirmDelivery;

  const _OrderPhaseActions({
    required this.order,
    required this.isBusy,
    required this.isUploadingPhoto,
    required this.onConfirmPreparation,
    required this.onMarkReady,
    required this.onTakeDeliveryPhoto,
    required this.onConfirmDelivery,
  });

  @override
  Widget build(BuildContext context) {
    if (!order.isCookViewer) {
      return _ConsumerOrderStatus(order: order);
    }

    switch (order.orderPhase) {
      case 'awaiting_preparation_confirmation':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isBusy ? null : onConfirmPreparation,
            icon: _busyIcon(isBusy, Icons.play_arrow),
            label: Text(isBusy ? 'Confirmando...' : 'Confirmar preparación'),
          ),
        );
      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isBusy ? null : onMarkReady,
            icon: _busyIcon(isBusy, Icons.restaurant),
            label: Text(isBusy ? 'Actualizando...' : 'Plato hecho'),
          ),
        );
      case 'ready':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isUploadingPhoto ? null : onTakeDeliveryPhoto,
                icon: _busyIcon(isUploadingPhoto, Icons.camera_alt),
                label: Text(
                  order.hasDeliveryPhoto
                      ? 'Tomar otra foto'
                      : isUploadingPhoto
                      ? 'Subiendo foto...'
                      : 'Tomar foto de entrega',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onConfirmDelivery,
                icon: _busyIcon(isBusy, Icons.check_circle),
                label: Text(
                  order.hasDeliveryPhoto
                      ? isBusy
                          ? 'Confirmando...'
                          : 'Confirmar entrega'
                      : 'Foto obligatoria para entregar',
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _busyIcon(bool busy, IconData icon) {
    if (!busy) return Icon(icon, size: 18);
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _ConsumerOrderStatus extends StatelessWidget {
  final Order order;
  const _ConsumerOrderStatus({required this.order});

  @override
  Widget build(BuildContext context) {
    final message = switch (order.orderPhase) {
      'awaiting_preparation_confirmation' =>
        'Te avisaremos cuando el cocinero confirme la preparación.',
      'preparing' => 'El cocinero ya está preparando tu plato.',
      'ready' =>
        'Tu plato está hecho. El cocinero debe confirmar la entrega con foto.',
      'delivered' || 'completed' => 'Pedido entregado.',
      _ => 'Sigue el estado del pedido aquí.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
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
