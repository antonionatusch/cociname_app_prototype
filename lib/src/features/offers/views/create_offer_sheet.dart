import 'package:flutter/material.dart';

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
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _priceController.dispose();
    _minutesController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
            'Presupuesto: Bs. ${widget.request.targetPrice.toStringAsFixed(0)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Publicación',
              border: OutlineInputBorder(),
            ),
            items:
                widget.publications
                    .where((p) => p.isActive)
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.title} - Bs. ${p.price.toStringAsFixed(0)}'),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _selectedPublicationId = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio ofertado',
                    border: OutlineInputBorder(),
                  ),
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
                    labelText: 'Minutos',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
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
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _createOffer,
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
    );
  }

  Future<void> _createOffer() async {
    if (_selectedPublicationId == null) {
      setState(() => _error = 'Selecciona una publicación');
      return;
    }

    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() => _error = 'Ingresa un precio válido');
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
        estimatedMinutes: int.tryParse(_minutesController.text.trim()),
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
