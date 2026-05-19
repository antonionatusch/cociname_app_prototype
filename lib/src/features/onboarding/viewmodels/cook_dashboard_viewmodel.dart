import 'package:flutter/foundation.dart';

import '../../dish_publication/models/dish_publication.dart';
import '../../dish_publication/repositories/dish_publication_repository.dart';

class CookDashboardViewModel extends ChangeNotifier {
  CookDashboardViewModel({required this.publicationRepository});

  final DishPublicationRepository publicationRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAvailable = true;
  bool get isAvailable => _isAvailable;

  String? _error;
  String? get error => _error;

  List<DishPublication> _publications = const [];
  List<DishPublication> get publications => _publications;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        publicationRepository.fetchOwnPublications(),
        publicationRepository.fetchCookAvailability(),
      ]);
      _publications = results[0] as List<DishPublication>;
      _isAvailable = results[1] as bool;
    } catch (_) {
      _error = 'No se pudo cargar tu panel. Intentalo nuevamente.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setAvailability(bool value) async {
    final previous = _isAvailable;
    _isAvailable = value;
    notifyListeners();

    try {
      await publicationRepository.setCookAvailability(value);
    } catch (_) {
      _isAvailable = previous;
      _error = 'No se pudo actualizar tu estado.';
      notifyListeners();
    }
  }

  Future<void> setPublicationActive(String publicationId, bool value) async {
    final previous = _publications;
    _publications =
        _publications
            .map(
              (publication) =>
                  publication.id == publicationId
                      ? publication.copyWith(isActive: value)
                      : publication,
            )
            .toList();
    notifyListeners();

    try {
      await publicationRepository.setPublicationActive(
        publicationId: publicationId,
        isActive: value,
      );
    } catch (_) {
      _publications = previous;
      _error = 'No se pudo actualizar el plato.';
      notifyListeners();
    }
  }
}
