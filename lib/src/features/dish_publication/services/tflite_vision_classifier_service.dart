import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/enums.dart';
import '../models/vision.dart';

class TfliteVisionClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const _modelPath = 'assets/models/food_classifier.tflite';
  static const _labelsPath = 'assets/models/food_classifier_labels.txt';

  static const _inputSize = 224;
  static const _recognizedThreshold = 0.75;
  static const _lowConfidenceThreshold = 0.45;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      final labelsContent = await rootBundle.loadString(_labelsPath);
      _labels =
          labelsContent
              .split('\n')
              .map((line) {
                final parts = line.trim().split(' ');
                return parts.length > 1
                    ? parts.sublist(1).join(' ')
                    : line.trim();
              })
              .where((label) => label.isNotEmpty)
              .toList();
    } catch (e) {
      throw Exception('Error al cargar el modelo TFLite: $e');
    }
  }

  bool get isInitialized => _interpreter != null && _labels != null;

  Future<VisionInferenceResult> classify(Uint8List imageBytes) async {
    if (!isInitialized) {
      throw Exception('El clasificador no ha sido inicializado');
    }

    final input = _preprocessImage(imageBytes);
    final output = List.filled(
      1 * (_labels?.length ?? 0),
      0.0,
    ).reshape([1, _labels!.length]);

    _interpreter!.run(input, output);

    final predictions = <VisionPrediction>[];
    for (var i = 0; i < _labels!.length; i++) {
      predictions.add(
        VisionPrediction(
          label: _labels![i],
          confidence: output[0][i] as double,
        ),
      );
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    final top = predictions.first;
    final status = _resolveStatus(top.confidence);

    return VisionInferenceResult(
      label: top.label,
      confidence: top.confidence,
      status: status,
      topPredictions: predictions.take(5).toList(),
    );
  }

  dynamic _preprocessImage(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
    );
    final input = List.filled(
      1 * _inputSize * _inputSize * 3,
      0.0,
    ).reshape([1, _inputSize, _inputSize, 3]);

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = (pixel.r / 255.0);
        input[0][y][x][1] = (pixel.g / 255.0);
        input[0][y][x][2] = (pixel.b / 255.0);
      }
    }

    return input;
  }

  VisionStatus _resolveStatus(double confidence) {
    if (confidence >= _recognizedThreshold) {
      return VisionStatus.recognized;
    }
    if (confidence >= _lowConfidenceThreshold) {
      return VisionStatus.lowConfidence;
    }
    return VisionStatus.unknown;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}
