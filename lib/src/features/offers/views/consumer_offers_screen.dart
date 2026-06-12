import 'package:flutter/material.dart';

import '../../dish_publication/models/dish_publication.dart';
import '../../offers/models/cook_offer.dart';

class ConsumerOffersScreen extends StatelessWidget {
  final List<CookOffer> offers;
  final Map<String, DishPublication> publications;

  const ConsumerOffersScreen({
    super.key,
    required this.offers,
    required this.publications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas recibidas')),
      body:
          offers.isEmpty
              ? const Center(child: Text('Aún no has recibido ofertas'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  final publication = publications[offer.publicationId];

                  final coverUrl = offer.coverPhotoPublicUrl;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child:
                                      coverUrl == null || coverUrl.isEmpty
                                          ? const Icon(
                                            Icons.restaurant,
                                            size: 30,
                                          )
                                          : Image.network(
                                            coverUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => const Icon(
                                                  Icons.broken_image,
                                                  size: 30,
                                                ),
                                          ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      publication?.title ?? 'Plato',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Total ofertado: Bs. ${offer.price.toStringAsFixed(2)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Cantidad: ${offer.requestedQuantity}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (offer.estimatedMinutes != null)
                                      Text(
                                        'Tiempo de preparación: ${offer.estimatedMinutes} min',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (offer.message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              offer.message,
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Ver detalle'),
                              ),
                              FilledButton(
                                onPressed:
                                    () => Navigator.of(context).pop(offer),
                                child: const Text('Aceptar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
