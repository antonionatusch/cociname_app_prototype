import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/vision.dart';
import '../viewmodels/publish_dish_viewmodel.dart';

class PublishDishScreen extends StatelessWidget {
  const PublishDishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PublishDishView();
  }
}

class _PublishDishView extends StatelessWidget {
  const _PublishDishView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PublishDishViewModel>();

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
              padding: const EdgeInsets.all(16),
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
                    label: 'Descripcion',
                    value: vm.description,
                    onChanged: vm.setDescription,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TextField(
                          label: 'Precio',
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
                          label: 'Cantidad',
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
        if (vm.imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(vm.imageFile!, height: 200, fit: BoxFit.cover),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('Sin imagen')),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    vm.isLoading
                        ? null
                        : () => vm.pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    vm.isLoading
                        ? null
                        : () => vm.pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeria'),
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
              'Detectado: ${result.label.replaceAll('_', ' ')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Confianza: ${(result.confidence * 100).toStringAsFixed(1)}%'),
            Text('Estado: ${result.status.databaseValue}'),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}

class _LocationSection extends StatelessWidget {
  final PublishDishViewModel vm;
  const _LocationSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            vm.title.isNotEmpty ? 'Ubicacion lista' : 'Ubicacion no capturada',
          ),
        ),
        TextButton.icon(
          onPressed: vm.captureLocation,
          icon: const Icon(Icons.location_on),
          label: const Text('Obtener'),
        ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final dynamic ingredient;
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
      title: Text(ingredient.displayName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ingredient.isConfirmedByCook)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: onConfirm,
              tooltip: 'Confirmar',
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
  bool _isCustom = false;

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
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  if (_isCustom) {
                    widget.vm.addCustomIngredient(text);
                  } else {
                    widget.vm.addKnownIngredient(text);
                  }
                  _controller.clear();
                },
                child: const Text('Agregar'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _isCustom,
              onChanged: (v) => setState(() => _isCustom = v ?? false),
            ),
            const Expanded(
              child: Text('Ingrediente personalizado (no genera alergen)'),
            ),
          ],
        ),
      ],
    );
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
