import 'package:flutter/material.dart';

import '../../dish_publication/utils/display_labels.dart';
import '../models/cook_offer.dart';

class AllergenWarningsSection extends StatelessWidget {
  final List<OfferAllergenWarning> warnings;
  final bool compact;

  const AllergenWarningsSection({
    super.key,
    required this.warnings,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final contains =
        warnings
            .where((item) => item.type == OfferAllergenWarningType.contains)
            .toList();
    final mayContain =
        warnings
            .where((item) => item.type == OfferAllergenWarningType.mayContain)
            .toList();

    if (contains.isEmpty && mayContain.isEmpty) {
      return _EmptyAllergenNotice(compact: compact);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contains.isNotEmpty)
          _WarningGroup(
            title: 'CONTIENE',
            description:
                'Ingredientes confirmados o agregados por el cocinero.',
            icon: Icons.warning_amber_rounded,
            color: Colors.deepOrange,
            warnings: contains,
            compact: compact,
          ),
        if (contains.isNotEmpty && mayContain.isNotEmpty)
          SizedBox(height: compact ? 8 : 12),
        if (mayContain.isNotEmpty)
          _WarningGroup(
            title: 'PUEDE CONTENER',
            description:
                'Ingredientes sugeridos o no confirmados por completo.',
            icon: Icons.info_outline,
            color: Colors.amber[800]!,
            warnings: mayContain,
            compact: compact,
          ),
        if (!compact) ...[
          const SizedBox(height: 12),
          Text(
            'Información preventiva basada en ingredientes declarados y sugerencias visuales. Confirma con el cocinero si tienes alergias severas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _WarningGroup extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<OfferAllergenWarning> warnings;
  final bool compact;

  const _WarningGroup({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.warnings,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: compact ? 18 : 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
            SizedBox(height: compact ? 6 : 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  warnings.map((warning) {
                    return _WarningChip(warning: warning, color: color);
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningChip extends StatelessWidget {
  final OfferAllergenWarning warning;
  final Color color;

  const _WarningChip({required this.warning, required this.color});

  @override
  Widget build(BuildContext context) {
    final allergen = _displayAllergenLabel(warning.name);
    final ingredient = _displayIngredientName(warning.ingredientName);

    return Chip(
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: Colors.white,
      label: Text('$allergen · $ingredient'),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyAllergenNotice extends StatelessWidget {
  final bool compact;

  const _EmptyAllergenNotice({required this.compact});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin alérgenos identificados en los ingredientes registrados.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayAllergenLabel(String value) {
  final normalized = value.trim();
  const labels = {
    'gluten': 'Gluten',
    'lacteos': 'Lácteos',
    'huevo': 'Huevo',
    'frutos_secos': 'Frutos secos',
    'mani': 'Maní',
    'soya': 'Soya',
  };
  return labels[normalized] ?? _displayFreeText(normalized);
}

String _displayIngredientName(String value) {
  return displayIngredientLabel(value.trim());
}

String _displayFreeText(String value) {
  final text = value
      .trim()
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
