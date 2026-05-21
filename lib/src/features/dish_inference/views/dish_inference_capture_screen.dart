import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../dish_publication/services/tflite_vision_classifier_service.dart';
import '../viewmodels/dish_inference_capture_viewmodel.dart';

class DishInferenceCaptureScreen extends StatelessWidget {
  const DishInferenceCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => DishInferenceCaptureViewModel(
            classifier: context.read<TfliteVisionClassifierService>(),
          ),
      child: const _CaptureView(),
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DishInferenceCaptureViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto del plato'),
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
          if (vm.canContinue)
            TextButton(
              onPressed: () {
                final result = vm.toCaptureResult();
                Navigator.of(context).pop(result);
              },
              child: const Text('Continuar'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (vm.error != null) _ErrorBanner(message: vm.error!),
          Expanded(child: _ImagePreview(vm: vm)),
          if (vm.inferenceResult != null) _InferenceCard(vm: vm),
          _ActionButtons(vm: vm),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final DishInferenceCaptureViewModel vm;
  const _ImagePreview({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.imageFile == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Toma o selecciona una foto del plato',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          vm.imageFile!,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _InferenceCard extends StatelessWidget {
  final DishInferenceCaptureViewModel vm;
  const _InferenceCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(vm.statusEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.detectedLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(vm.confidenceText),
                  Text(
                    vm.visionStatusText,
                    style: TextStyle(
                      color:
                          vm.inferenceResult!.status.name == 'recognized'
                              ? AppTheme.success
                              : AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final DishInferenceCaptureViewModel vm;
  const _ActionButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 16 + MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  vm.isLoading
                      ? null
                      : () => vm.pickAndClassify(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar foto'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  vm.isLoading
                      ? null
                      : () => vm.pickAndClassify(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Seleccionar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red[100],
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}
