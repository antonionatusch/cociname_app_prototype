import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../dish_inference/models/inference_capture_result.dart';
import '../../maps/views/location_picker_screen.dart';
import '../models/dish_ingredient.dart';
import '../models/vision.dart';
import '../utils/display_labels.dart';
import '../viewmodels/publish_dish_viewmodel.dart';

class PublishDishScreen extends StatelessWidget {
  const PublishDishScreen({super.key, this.captureResult});

  final InferenceCaptureResult? captureResult;

  @override
  Widget build(BuildContext context) {
    return _PublishDishView(captureResult: captureResult);
  }
}

class _PublishDishView extends StatelessWidget {
  const _PublishDishView({this.captureResult});

  final InferenceCaptureResult? captureResult;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PublishDishViewModel>();
    final bottomPadding = 24 + MediaQuery.of(context).viewPadding.bottom;

    if (vm.isPublished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(true);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar plato'),
        actions: [
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (vm.error != null) _ErrorBanner(message: vm.error!),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImagePickerSection(vm: vm),
                  const SizedBox(height: 16),
                  if (vm.inferenceResult != null)
                    _InferenceResultCard(result: vm.inferenceResult!),
                  if (vm.inferenceResult != null) const SizedBox(height: 16),
                  _TextField(
                    label: 'Nombre del plato',
                    value: vm.title,
                    onChanged: vm.setTitle,
                  ),
                  const SizedBox(height: 8),
                  _TextField(
                    label: 'Descripción',
                    value: vm.description,
                    onChanged: vm.setDescription,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TextField(
                          label: 'Precio unitario (Bs.)',
                          value: vm.priceText,
                          onChanged: vm.setPriceText,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TextField(
                          label: 'Cantidad disponible',
                          value: vm.quantityText,
                          onChanged: vm.setQuantityText,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _LocationSection(vm: vm),
                  const SizedBox(height: 16),
                  const Text(
                    'Ingredientes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...vm.ingredients.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ingredient = entry.value;
                    return _IngredientTile(
                      ingredient: ingredient,
                      onConfirm: () => vm.confirmIngredient(index),
                      onRemove: () => vm.removeIngredient(index),
                    );
                  }),
                  const SizedBox(height: 8),
                  _AddIngredientSection(vm: vm),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: vm.isLoading ? null : () => vm.publish(),
                    child: const Text('Publicar'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final PublishDishViewModel vm;
  const _ImagePickerSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child:
              vm.imageFiles.isEmpty
                  ? Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('Sin imagen')),
                  )
                  : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vm.imageFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              vm.imageFiles[index],
                              width: 220,
                              height: 210,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Text(
                                  index == 0 ? 'Portada' : 'Foto ${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: IconButton.filled(
                              onPressed:
                                  vm.isLoading
                                      ? null
                                      : () => vm.removePhoto(index),
                              icon: const Icon(Icons.close),
                              tooltip: 'Quitar foto',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
        ),
        const SizedBox(height: 8),
        Text(
          '${vm.imageFiles.length}/3 fotos. La primera será la portada del dashboard.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    vm.isLoading || vm.imageFiles.length >= 3
                        ? null
                        : () => vm.pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    vm.isLoading || vm.imageFiles.length >= 3
                        ? null
                        : vm.pickImagesFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería múltiple'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InferenceResultCard extends StatelessWidget {
  final VisionInferenceResult result;
  const _InferenceResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detectado: ${displayFoodLabel(result.label)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Confianza: ${(result.confidence * 100).toStringAsFixed(1)}%'),
            Text('Resultado: ${displayVisionStatus(result.status)}'),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
    );
  }
}

class _LocationSection extends StatelessWidget {
  final PublishDishViewModel vm;
  const _LocationSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                vm.hasLocation ? Icons.location_on : Icons.location_searching,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.hasLocation
                          ? 'Ubicación lista'
                          : 'Ubicación pendiente',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vm.hasLocation
                          ? vm.locationLabel
                          : 'Selecciona tu ubicación para la publicación.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: vm.isLoading ? null : vm.captureLocation,
                child: Text(vm.hasLocation ? 'GPS' : 'GPS'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<dynamic>(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen(),
                      ),
                    );
                    if (result != null && context.mounted) {
                      vm.setLocation(result);
                    }
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text(
                    'Elegir en mapa',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<dynamic>(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen(),
                      ),
                    );
                    if (result != null && context.mounted) {
                      vm.setLocation(result);
                    }
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(
                    'Buscar dirección',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final DishIngredient ingredient;
  final VoidCallback onConfirm;
  final VoidCallback onRemove;
  const _IngredientTile({
    required this.ingredient,
    required this.onConfirm,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(displayIngredientLabel(ingredient.displayName)),
      subtitle:
          ingredient.isConfirmedByCook
              ? null
              : const Text('Sugerido por la foto. Confírmalo si aplica.'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ingredient.isConfirmedByCook)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: onConfirm,
              tooltip: 'Confirmar ingrediente',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onRemove,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

class _AddIngredientSection extends StatefulWidget {
  final PublishDishViewModel vm;
  const _AddIngredientSection({required this.vm});

  @override
  State<_AddIngredientSection> createState() => _AddIngredientSectionState();
}

class _AddIngredientSectionState extends State<_AddIngredientSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Agregar ingrediente',
                  hintText: 'Ej.: harina integral',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addIngredient(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: _addIngredient,
                child: const Text('Agregar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Si coincide con el catálogo, se usará para detectar alérgenos. Si no, se guardará como texto libre.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _addIngredient() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.vm.addIngredient(text);
    _controller.clear();
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red[100],
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}
