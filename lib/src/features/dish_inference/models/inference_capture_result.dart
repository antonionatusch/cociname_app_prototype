import 'dart:io';

import '../../dish_publication/models/vision.dart';

class InferenceCaptureResult {
  final File imageFile;
  final VisionInferenceResult inferenceResult;
  final String detectedLabel;
  final double confidence;

  const InferenceCaptureResult({
    required this.imageFile,
    required this.inferenceResult,
    required this.detectedLabel,
    required this.confidence,
  });
}
