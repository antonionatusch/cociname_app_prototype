import 'package:flutter/material.dart';

import '../../dish_publication/utils/display_labels.dart';
import '../models/cook_offer.dart';
import 'allergen_warnings_section.dart';

class OfferDetailScreen extends StatelessWidget {
  final CookOffer offer;

  const OfferDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = 28 + MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de oferta')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
        children: [
          _PhotoCarousel(offer: offer),
          const SizedBox(height: 18),
          Text(
            offer.dishTitle ?? 'Oferta de plato',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.storefront, size: 18, color: Colors.orange[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  offer.cookBusinessName ?? 'Cocinero disponible',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                icon: Icons.payments,
                label: 'Total Bs. ${offer.price.toStringAsFixed(2)}',
              ),
              _MetricChip(
                icon: Icons.format_list_numbered,
                label: 'Cantidad ${offer.requestedQuantity}',
              ),
              if (offer.estimatedMinutes != null)
                _MetricChip(
                  icon: Icons.timer_outlined,
                  label: 'Preparación ${offer.estimatedMinutes} min',
                ),
              if (offer.distanceKm != null)
                _MetricChip(
                  icon: Icons.near_me_outlined,
                  label: '${offer.distanceKm!.toStringAsFixed(1)} km',
                ),
              if (offer.dishRatingAverage != null)
                _MetricChip(
                  icon: Icons.star,
                  label: 'Plato ${offer.dishRatingAverage!.toStringAsFixed(1)}',
                ),
              if (offer.cookRatingAverage != null)
                _MetricChip(
                  icon: Icons.storefront,
                  label:
                      'Cocinero ${offer.cookRatingAverage!.toStringAsFixed(1)}',
                ),
            ],
          ),
          if (offer.publicationZoneLabel != null &&
              offer.publicationZoneLabel!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(offer.publicationZoneLabel!)),
              ],
            ),
          ],
          if (offer.dishDescription != null &&
              offer.dishDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Descripción', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(offer.dishDescription!),
          ],
          if (offer.message.trim().isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Mensaje del cocinero', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(offer.message),
          ],
          const SizedBox(height: 22),
          Text('Ingredientes registrados', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          if (offer.ingredients.isEmpty)
            Text(
              'El cocinero aún no registró ingredientes visibles para esta oferta.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  offer.ingredients.map((ingredient) {
                    return Chip(
                      avatar: Icon(
                        ingredient.isConfirmedByCook
                            ? Icons.verified_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      label: Text(displayIngredientLabel(ingredient.name)),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
            ),
          const SizedBox(height: 22),
          Text('Advertencias de alérgenos', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          AllergenWarningsSection(warnings: offer.allergenWarnings),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                offer.status == 'pending'
                    ? () => Navigator.of(context).pop(offer.id)
                    : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Aceptar oferta'),
          ),
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  final CookOffer offer;

  const _PhotoCarousel({required this.offer});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.offer.dishPhotos;
    final fallbackUrl = widget.offer.dishPhotoPublicUrl;

    if (photos.isEmpty && (fallbackUrl == null || fallbackUrl.isEmpty)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: ColoredBox(
            color: Colors.orange[50]!,
            child: const Icon(Icons.restaurant, size: 64),
          ),
        ),
      );
    }

    final imageUrls =
        photos.isNotEmpty
            ? photos
                .map((photo) => photo.publicUrl)
                .where((url) => url.isNotEmpty)
                .toList()
            : [fallbackUrl!];

    if (imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: ColoredBox(
            color: Colors.orange[50]!,
            child: const Icon(Icons.restaurant, size: 64),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => ColoredBox(
                        color: Colors.orange[50]!,
                        child: const Icon(Icons.broken_image, size: 64),
                      ),
                );
              },
            ),
            if (imageUrls.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.deepOrange),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
