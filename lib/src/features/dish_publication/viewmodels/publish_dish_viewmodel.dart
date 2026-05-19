import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../maps/models/selected_location.dart';
import '../models/dish_ingredient.dart';
import '../models/enums.dart';
import '../models/vision.dart';
import '../repositories/dish_publication_repository.dart';
import '../repositories/ingredient_repository.dart';
import '../services/location_service.dart';
import '../services/tflite_vision_classifier_service.dart';
import '../utils/display_labels.dart';

class PublishDishViewModel extends ChangeNotifier {
  PublishDishViewModel({
    required this.classifier,
    required this.locationService,
    required this.publicationRepository,
    required this.ingredientRepository,
  });

  final TfliteVisionClassifierService classifier;
  final LocationService locationService;
  final DishPublicationRepository publicationRepository;
  final IngredientRepository ingredientRepository;

  final List<File> _imageFiles = [];
  List<File> get imageFiles => List.unmodifiable(_imageFiles);
  File? get imageFile => _imageFiles.isEmpty ? null : _imageFiles.first;

  bool _hasConfirmedInference = false;
  bool get hasConfirmedInference => _hasConfirmedInference;

  VisionInferenceResult? _inferenceResult;
  VisionInferenceResult? get inferenceResult => _inferenceResult;

  String _title = '';
  String get title => _title;

  String _description = '';
  String get description => _description;

  String _priceText = '';
  String get priceText => _priceText;

  String _quantityText = '';
  String get quantityText => _quantityText;

  double? _latitude;
  double? _longitude;
  String? _zoneLabel;
  bool get hasLocation => _latitude != null && _longitude != null;
  String get locationLabel => _zoneLabel ?? 'Ubicación no capturada';

  final List<DishIngredient> _ingredients = [];
  List<DishIngredient> get ingredients => List.unmodifiable(_ingredients);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isPublished = false;
  bool get isPublished => _isPublished;

  static const Map<String, List<String>> _suggestedIngredientsByCategory = {
    'pizza': ['harina_trigo', 'queso', 'tomate', 'levadura'],
    'empanada_queso_frita': ['harina_trigo', 'queso', 'mantequilla', 'huevo'],
    'empanada_queso_integral': [
      'harina_integral',
      'queso',
      'mantequilla',
      'huevo',
    ],
    'hamburguesa': ['pan_hamburguesa', 'carne', 'queso', 'huevo'],
    'cunape': ['almidon_yuca', 'queso', 'huevo', 'leche'],
  };

  void initializeWithInference(File firstPhoto, VisionInferenceResult result) {
    _imageFiles.add(firstPhoto);
    _inferenceResult = result;
    _hasConfirmedInference = true;
    _title = displayFoodLabel(result.label);
    final category = result.label;
    final suggestedCodes = _suggestedIngredientsByCategory[category] ?? [];
    for (final code in suggestedCodes) {
      _ingredients.add(
        DishIngredient(
          ingredientId: code,
          source: IngredientSource.visionSuggested,
          isConfirmedByCook: false,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    _clearError();
    if (_imageFiles.length >= 3) {
      _error = 'Puedes agregar hasta 3 fotos por plato';
      notifyListeners();
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    _imageFiles.add(File(picked.path));
    notifyListeners();
  }

  Future<void> pickImagesFromGallery() async {
    _clearError();
    final remainingSlots = 3 - _imageFiles.length;
    if (remainingSlots <= 0) {
      _error = 'Puedes agregar hasta 3 fotos por plato';
      notifyListeners();
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final selected = picked.take(remainingSlots).map((item) => File(item.path));
    _imageFiles.addAll(selected);
    if (picked.length > remainingSlots) {
      _error = 'Solo se agregaron $remainingSlots foto(s). El máximo es 3.';
    }
    notifyListeners();
  }

  Future<void> removePhoto(int index) async {
    if (index < 0 || index >= _imageFiles.length) return;
    final removedFirst = index == 0;
    _imageFiles.removeAt(index);
    if (_imageFiles.isEmpty) {
      _inferenceResult = null;
      _hasConfirmedInference = false;
      _title = '';
      _ingredients.clear();
      notifyListeners();
      return;
    }

    notifyListeners();
    if (removedFirst && _hasConfirmedInference) {
      _error = 'La inferencia ya fue realizada para la foto inicial. '
          'Si cambias la portada, no se ejecutará un nuevo análisis automático.';
      notifyListeners();
    }
  }

  void confirmIngredient(int index) {
    if (index >= 0 && index < _ingredients.length) {
      final current = _ingredients[index];
      _ingredients[index] = DishIngredient(
        ingredientId: current.ingredientId,
        customName: current.customName,
        source: IngredientSource.cookConfirmed,
        isConfirmedByCook: true,
      );
      notifyListeners();
    }
  }

  void removeIngredient(int index) {
    if (index >= 0 && index < _ingredients.length) {
      _ingredients.removeAt(index);
      notifyListeners();
    }
  }

  void addKnownIngredient(String ingredientCode) {
    final trimmed = ingredientCode.trim();
    if (trimmed.isEmpty) return;
    _ingredients.add(
      DishIngredient(
        ingredientId: trimmed,
        source: IngredientSource.cookManual,
        isConfirmedByCook: true,
      ),
    );
    notifyListeners();
  }

  void addIngredient(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    final knownCode = knownIngredientCodeFromInput(trimmed);
    if (knownCode != null) {
      addKnownIngredient(knownCode);
      return;
    }

    addCustomIngredient(displayFreeTextLabel(trimmed));
  }

  void addCustomIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _ingredients.add(
      DishIngredient(
        customName: trimmed,
        source: IngredientSource.customManual,
        isConfirmedByCook: true,
      ),
    );
    notifyListeners();
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setPriceText(String value) {
    _priceText = value;
    notifyListeners();
  }

  void setQuantityText(String value) {
    _quantityText = value;
    notifyListeners();
  }

  void setLocation(SelectedLocation location) {
    _latitude = location.latitude;
    _longitude = location.longitude;
    _zoneLabel = location.addressLabel;
    notifyListeners();
  }

  Future<void> captureLocation() async {
    _clearError();
    final result = await locationService.getCurrentPosition();
    final position = result.position;

    if (position != null) {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _zoneLabel =
          result.address ??
          _formatCoordinates(position.latitude, position.longitude);
      notifyListeners();
    } else {
      _error = _locationErrorMessage(result.failure);
      notifyListeners();
    }
  }

  String _locationErrorMessage(LocationFailure? failure) {
    return switch (failure) {
      LocationFailure.serviceDisabled =>
        'Activa la ubicación del dispositivo para capturar tu posición',
      LocationFailure.permissionDenied =>
        'Necesitamos permiso de ubicación para publicar el plato',
      LocationFailure.permissionPermanentlyDenied =>
        'El permiso de ubicación está bloqueado. Habilítalo desde ajustes',
      LocationFailure.unavailable || null => 'No se pudo obtener la ubicación',
    };
  }

  String _formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  Future<void> publish() async {
    _clearError();

    final validationError = _validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final photoPaths = <String>[];
      for (var index = 0; index < _imageFiles.length; index++) {
        final photoPath = await publicationRepository.uploadPhoto(
          _imageFiles[index],
          position: index + 1,
        );
        photoPaths.add(photoPath);
      }

      final knownIngredients =
          _ingredients
              .where((i) => i.isKnown)
              .map(
                (i) => {
                  'code': i.ingredientId,
                  'source': i.source.databaseValue,
                  'is_confirmed_by_cook': i.isConfirmedByCook,
                },
              )
              .toList();

      final customIngredients =
          _ingredients
              .where((i) => !i.isKnown)
              .map(
                (i) => {'name': i.customName, 'source': i.source.databaseValue},
              )
              .toList();

      final visionLog = _inferenceResult?.toLogPayload();

      await publicationRepository.createPublication(
        title: _title,
        description: _description,
        price: double.parse(_priceText),
        availableQuantity: int.parse(_quantityText),
        categoryCode: _inferenceResult?.label ?? 'unknown_food',
        visionStatus: _inferenceResult?.status ?? VisionStatus.manualOnly,
        visionConfidence: _inferenceResult?.confidence,
        detectedLabel: _inferenceResult?.label,
        manualFoodName: _inferenceResult == null ? _title : null,
        latitude: _latitude,
        longitude: _longitude,
        zoneLabel: _zoneLabel,
        photoStoragePaths: photoPaths,
        ingredients: knownIngredients,
        customIngredients: customIngredients,
        visionLog: visionLog,
      );

      _isPublished = true;
    } catch (e) {
      _error = _publishErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  String? _validate() {
    if (_imageFiles.isEmpty) return 'Selecciona al menos una foto';
    if (_imageFiles.length > 3) return 'Puedes agregar hasta 3 fotos por plato';
    if (_title.trim().isEmpty) return 'Ingresa el nombre del plato';
    if (_priceText.isEmpty) return 'Ingresa el precio';
    if (double.tryParse(_priceText) == null || double.parse(_priceText) <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    if (_quantityText.isEmpty) return 'Ingresa la cantidad disponible';
    if (int.tryParse(_quantityText) == null || int.parse(_quantityText) <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    if (_ingredients.isEmpty) return 'Agrega al menos un ingrediente';
    return null;
  }

  String _publishErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('Bucket not found')) {
      return 'No se pudo subir la foto porque falta configurar el almacenamiento de platos.';
    }
    if (message.contains('Usuario no autenticado')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente para publicar.';
    }
    return 'No se pudo publicar el plato. Revisa los datos e inténtalo nuevamente.';
  }

  void _clearError() {
    _error = null;
  }

  void reset() {
    _imageFiles.clear();
    _inferenceResult = null;
    _hasConfirmedInference = false;
    _title = '';
    _description = '';
    _priceText = '';
    _quantityText = '';
    _latitude = null;
    _longitude = null;
    _zoneLabel = null;
    _ingredients.clear();
    _isLoading = false;
    _error = null;
    _isPublished = false;
    notifyListeners();
  }
}
