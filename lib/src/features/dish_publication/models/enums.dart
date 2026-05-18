enum VisionStatus {
  recognized,
  lowConfidence,
  unknown,
  manualOnly,
}

extension VisionStatusExtension on VisionStatus {
  String get databaseValue {
    switch (this) {
      case VisionStatus.recognized:
        return 'recognized';
      case VisionStatus.lowConfidence:
        return 'low_confidence';
      case VisionStatus.unknown:
        return 'unknown';
      case VisionStatus.manualOnly:
        return 'manual_only';
    }
  }

  static VisionStatus fromDatabaseValue(String value) {
    switch (value) {
      case 'recognized':
        return VisionStatus.recognized;
      case 'low_confidence':
        return VisionStatus.lowConfidence;
      case 'unknown':
        return VisionStatus.unknown;
      case 'manual_only':
        return VisionStatus.manualOnly;
      default:
        return VisionStatus.unknown;
    }
  }
}

enum IngredientSource {
  visionSuggested,
  cookConfirmed,
  cookManual,
  customManual,
}

extension IngredientSourceExtension on IngredientSource {
  String get databaseValue {
    switch (this) {
      case IngredientSource.visionSuggested:
        return 'vision_suggested';
      case IngredientSource.cookConfirmed:
        return 'cook_confirmed';
      case IngredientSource.cookManual:
        return 'cook_manual';
      case IngredientSource.customManual:
        return 'custom_manual';
    }
  }

  static IngredientSource fromDatabaseValue(String value) {
    switch (value) {
      case 'vision_suggested':
        return IngredientSource.visionSuggested;
      case 'cook_confirmed':
        return IngredientSource.cookConfirmed;
      case 'cook_manual':
        return IngredientSource.cookManual;
      case 'custom_manual':
        return IngredientSource.customManual;
      default:
        return IngredientSource.cookManual;
    }
  }
}
