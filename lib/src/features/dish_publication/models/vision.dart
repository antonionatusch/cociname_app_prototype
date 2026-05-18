import 'enums.dart';

class VisionPrediction {
  final String label;
  final double confidence;

  const VisionPrediction({
    required this.label,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {'label': label, 'confidence': confidence};
  }
}

class VisionInferenceResult {
  final String label;
  final double confidence;
  final VisionStatus status;
  final List<VisionPrediction> topPredictions;

  const VisionInferenceResult({
    required this.label,
    required this.confidence,
    required this.status,
    this.topPredictions = const [],
  });

  Map<String, dynamic> toLogPayload() {
    return {
      'model_version': 'tecnoupsa-v1',
      'predicted_label': label,
      'confidence': confidence,
      'vision_status': status.databaseValue,
      'top_predictions': topPredictions.map((p) => p.toMap()).toList(),
    };
  }
}
