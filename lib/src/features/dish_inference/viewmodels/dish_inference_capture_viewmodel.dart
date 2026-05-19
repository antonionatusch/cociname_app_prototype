import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../dish_publication/models/enums.dart';
import '../../dish_publication/models/vision.dart';
import '../../dish_publication/services/tflite_vision_classifier_service.dart';
import '../../dish_publication/utils/display_labels.dart';
import '../models/inference_capture_result.dart';

class DishInferenceCaptureViewModel extends ChangeNotifier {
  DishInferenceCaptureViewModel({required this.classifier});

  final TfliteVisionClassifierService classifier;

  File? _imageFile;
  VisionInferenceResult? _inferenceResult;
  bool _isLoading = false;
  String? _error;
  bool _canContinue = false;

  File? get imageFile => _imageFile;
  VisionInferenceResult? get inferenceResult => _inferenceResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canContinue => _canContinue;

  String get detectedLabel {
    if (_inferenceResult == null) return '';
    return displayFoodLabel(_inferenceResult!.label);
  }

  String get confidenceText {
    if (_inferenceResult == null) return '';
    return '${(_inferenceResult!.confidence * 100).toStringAsFixed(1)}%';
  }

  String get visionStatusText {
    if (_inferenceResult == null) return '';
    return displayVisionStatus(_inferenceResult!.status);
  }

  String get statusEmoji {
    if (_inferenceResult == null) return '';
    return switch (_inferenceResult!.status) {
      VisionStatus.recognized => '✅',
      VisionStatus.lowConfidence => '⚠️',
      VisionStatus.unknown => '❓',
      VisionStatus.manualOnly => '✏️',
    };
  }

  Future<void> pickAndClassify(ImageSource source) async {
    _clearError();

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    _imageFile = File(picked.path);
    _inferenceResult = null;
    _canContinue = false;
    notifyListeners();

    await _runClassification();
  }

  Future<void> _runClassification() async {
    if (_imageFile == null || !classifier.isInitialized) {
      _error = 'No hay imagen o el clasificador no está listo';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bytes = await _imageFile!.readAsBytes();
      _inferenceResult = await classifier.classify(bytes);
      _canContinue = true;
    } catch (e) {
      _error = 'Error al clasificar la imagen: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  InferenceCaptureResult toCaptureResult() {
    if (_imageFile == null || _inferenceResult == null) {
      throw Exception('No hay imagen o inferencia para continuar');
    }
    return InferenceCaptureResult(
      imageFile: _imageFile!,
      inferenceResult: _inferenceResult!,
      detectedLabel: detectedLabel,
      confidence: _inferenceResult!.confidence,
    );
  }

  void _clearError() {
    _error = null;
  }
}
