import 'package:flutter/material.dart';

import '../../../core/helpers/allergen_display_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../consumer/models/consumer_request.dart';
import '../../dish_publication/models/dish_publication.dart';
import '../repositories/offer_repository.dart';

class CreateOfferSheet extends StatefulWidget {
  final ConsumerRequest request;
  final List<DishPublication> publications;

  const CreateOfferSheet({
    super.key,
    required this.request,
    required this.publications,
  });

  @override
  State<CreateOfferSheet> createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<CreateOfferSheet> {
  String? _selectedPublicationId;
  final _priceController = TextEditingController();
  final _minutesController = TextEditingController();
  final _messageController = TextEditingController();
  bool _priceWasEdited = false;
  bool _isSaving = false;
  String? _error;

  DishPublication? get _selectedPublication {
    final id = _selectedPublicationId;
    if (id == null) return null;
    for (final publication in widget.publications) {
      if (publication.id == id) return publication;
    }
    return null;
  }

  bool get _hasIncompatibleAllergens {
    final publication = _selectedPublication;
    if (publication == null) return false;
    if (widget.request.allergenFilters.isEmpty) return false;
    return widget.request.allergenFilters.any(
      (filter) => publication.allergenCodes.contains(filter),
    );
  }

  double? get _referenceTotal {
    final publication = _selectedPublication;
    if (publication == null) return null;
    return publication.price * widget.request.requestedQuantity;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _minutesController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding =
        mediaQuery.viewInsets.bottom > 0
            ? mediaQuery.viewInsets.bottom + 20
            : mediaQuery.viewPadding.bottom + 20;
    final selectedPublication = _selectedPublication;
    final referenceTotal = _referenceTotal;
    final hasInsufficientQuantity =
        selectedPublication != null &&
        selectedPublication.availableQuantity <
            widget.request.requestedQuantity;
    final hasIncompatibleAllergens = _hasIncompatibleAllergens;
    final bool canSubmit =
        _selectedPublicationId != null &&
        !hasInsufficientQuantity &&
        !hasIncompatibleAllergens;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            Text(
              'Ofertar para: ${widget.request.queryText}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Cantidad solicitada: ${widget.request.requestedQuantity}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Presupuesto total: Bs. ${widget.request.targetPrice.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              widget.request.allergenFilters.isEmpty
                  ? 'Sin alergias declaradas'
                  : 'Alérgico a: ${formatAllergenFilters(widget.request.allergenFilters)}',
              style: TextStyle(
                color:
                    widget.request.allergenFilters.isEmpty
                        ? Colors.grey[600]
                        : Colors.red[700],
                fontWeight:
                    widget.request.allergenFilters.isNotEmpty
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Publicación',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.publications.where((p) => p.isActive).map((p) {
                    final hasAllergenConflict = widget.request.allergenFilters
                        .any((f) => p.allergenCodes.contains(f));
                    final insufficientStock =
                        p.availableQuantity < widget.request.requestedQuantity;
                    String hint = '';
                    if (hasAllergenConflict) {
                      hint =
                          ' - Contiene ${formatAllergenFilters(p.allergenCodes.where((c) => widget.request.allergenFilters.contains(c)).toList())}';
                    }
                    return DropdownMenuItem(
                      value: p.id,
                      enabled: !hasAllergenConflict && !insufficientStock,
                      child: Text(
                        '${p.title} - Bs. ${p.price.toStringAsFixed(0)} - Disp: ${p.availableQuantity}$hint',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: _onPublicationChanged,
            ),
            if (selectedPublication != null) ...[
              const SizedBox(height: 12),
              _ReferencePriceCard(
                unitPrice: selectedPublication.price,
                requestedQuantity: widget.request.requestedQuantity,
                referenceTotal: referenceTotal ?? 0,
                availableQuantity: selectedPublication.availableQuantity,
                hasInsufficientQuantity: hasInsufficientQuantity,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio total ofertado',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _priceWasEdited = true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    decoration: const InputDecoration(
                      labelText: 'Tiempo de preparación (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Este es el total de la oferta para ${widget.request.requestedQuantity} unidad(es). Puedes ajustarlo si harás descuento o necesitas cambiar el monto.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (hasIncompatibleAllergens) ...[
              const SizedBox(height: 8),
              const Text(
                'Esta publicación contiene alérgenos restringidos por el consumidor.',
                style: TextStyle(color: AppTheme.error),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_isSaving || !canSubmit) ? null : _createOffer,
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Enviar oferta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPublicationChanged(String? value) {
    setState(() {
      _selectedPublicationId = value;
      _applyReferenceTotal(force: !_priceWasEdited);
    });
  }

  void _applyReferenceTotal({required bool force}) {
    final referenceTotal = _referenceTotal;
    if (referenceTotal == null) return;
    if (force || _priceController.text.trim().isEmpty) {
      _priceController.text = referenceTotal.toStringAsFixed(2);
    }
  }

  Future<void> _createOffer() async {
    if (_selectedPublicationId == null) {
      setState(() => _error = 'Selecciona una publicación');
      return;
    }

    final publication = _selectedPublication;
    if (publication != null &&
        publication.availableQuantity < widget.request.requestedQuantity) {
      setState(
        () =>
            _error =
                'Solo tienes ${publication.availableQuantity} disponible(s) para una solicitud de ${widget.request.requestedQuantity}.',
      );
      return;
    }

    if (_hasIncompatibleAllergens) {
      setState(
        () =>
            _error =
                'Esta publicación contiene alérgenos restringidos por el consumidor.',
      );
      return;
    }

    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() => _error = 'Ingresa un precio válido');
      return;
    }
    final minutesText = _minutesController.text.trim();
    final minutes = int.tryParse(minutesText);
    if (minutesText.isNotEmpty && (minutes == null || minutes <= 0)) {
      setState(() => _error = 'Ingresa un tiempo de preparación válido');
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    try {
      final repo = OfferRepository();
      await repo.createOffer(
        requestId: widget.request.id,
        publicationId: _selectedPublicationId!,
        price: price,
        estimatedMinutes: minutes,
        message: _messageController.text.trim(),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Error al crear oferta: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ReferencePriceCard extends StatelessWidget {
  const _ReferencePriceCard({
    required this.unitPrice,
    required this.requestedQuantity,
    required this.referenceTotal,
    required this.availableQuantity,
    required this.hasInsufficientQuantity,
  });

  final double unitPrice;
  final int requestedQuantity;
  final double referenceTotal;
  final int availableQuantity;
  final bool hasInsufficientQuantity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasInsufficientQuantity ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasInsufficientQuantity ? AppTheme.error : Colors.orange[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referencia para tu oferta',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Precio unitario publicado: Bs. ${unitPrice.toStringAsFixed(2)}',
            ),
            Text('Cantidad solicitada: $requestedQuantity'),
            Text('Total referencial: Bs. ${referenceTotal.toStringAsFixed(2)}'),
            Text('Cantidad disponible: $availableQuantity'),
            if (hasInsufficientQuantity) ...[
              const SizedBox(height: 6),
              const Text(
                'No tienes suficiente cantidad disponible para esta solicitud.',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
