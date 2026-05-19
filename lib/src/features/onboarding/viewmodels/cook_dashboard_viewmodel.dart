import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../consumer/models/consumer_request.dart';
import '../../dish_publication/models/dish_publication.dart';
import '../../dish_publication/repositories/dish_publication_repository.dart';
import '../repositories/cook_request_repository.dart';

class CookDashboardViewModel extends ChangeNotifier {
  CookDashboardViewModel({
    required this.publicationRepository,
    required this.cookRequestRepository,
  }) {
    _startPolling();
  }

  final DishPublicationRepository publicationRepository;
  final CookRequestRepository cookRequestRepository;
  Timer? _pollTimer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAvailable = true;
  bool get isAvailable => _isAvailable;

  String? _error;
  String? get error => _error;

  List<DishPublication> _publications = const [];
  List<DishPublication> get publications => _publications;

  List<ConsumerRequest> _incomingRequests = const [];
  List<ConsumerRequest> get incomingRequests => _incomingRequests;

  bool _hasIncomingRequests = false;
  bool get hasIncomingRequests => _hasIncomingRequests;

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollIncomingRequests();
    });
  }

  Future<void> _pollIncomingRequests() async {
    if (!_isAvailable) return;

    try {
      _incomingRequests = await cookRequestRepository.fetchActiveRequests(
        maxRadiusKm: 10,
      );
      _hasIncomingRequests = _incomingRequests.isNotEmpty;
      notifyListeners();
    } catch (_) {}
  }

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

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> setAvailability(bool value) async {
    final previous = _isAvailable;
    _isAvailable = value;
    _error = null;
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
    _error = null;
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

  Future<bool> updatePublication({
    required String publicationId,
    required String title,
    required String description,
    required double price,
    required int availableQuantity,
    double? latitude,
    double? longitude,
    String? zoneLabel,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await publicationRepository.updatePublication(
        publicationId: publicationId,
        title: title,
        description: description,
        price: price,
        availableQuantity: availableQuantity,
        latitude: latitude,
        longitude: longitude,
        zoneLabel: zoneLabel,
      );
      _publications =
          _publications
              .map(
                (publication) =>
                    publication.id == publicationId
                        ? publication.copyWith(
                          title: title,
                          description: description,
                          price: price,
                          availableQuantity: availableQuantity,
                        )
                        : publication,
              )
              .toList();
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'No se pudo modificar la publicación.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePublication(DishPublication publication) async {
    _error = null;
    notifyListeners();

    try {
      await publicationRepository.deletePausedPublication(publication);
      _publications =
          _publications.where((item) => item.id != publication.id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      _error =
          publication.isActive
              ? 'Pausa la publicación antes de eliminarla.'
              : 'No se pudo eliminar la publicación.';
      notifyListeners();
      return false;
    }
  }
}
