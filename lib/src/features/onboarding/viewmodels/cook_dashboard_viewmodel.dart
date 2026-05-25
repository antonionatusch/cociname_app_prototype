import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../consumer/models/consumer_request.dart';
import '../../dish_publication/models/dish_publication.dart';
import '../../dish_publication/repositories/dish_publication_repository.dart';
import '../../offers/models/cook_active_offer.dart';
import '../../offers/repositories/offer_repository.dart';
import '../../orders/models/order.dart';
import '../../orders/repositories/order_repository.dart';
import '../repositories/cook_request_repository.dart';

class CookDashboardViewModel extends ChangeNotifier {
  CookDashboardViewModel({
    required this.publicationRepository,
    required this.cookRequestRepository,
    required this.orderRepository,
    required this.offerRepository,
  }) {
    _startPolling();
  }

  final DishPublicationRepository publicationRepository;
  final CookRequestRepository cookRequestRepository;
  final OrderRepository orderRepository;
  final OfferRepository offerRepository;
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
  final Set<String> _ignoredRequestIds = {};

  bool _hasIncomingRequests = false;
  bool get hasIncomingRequests => _hasIncomingRequests;

  List<CookActiveOffer> _activeOffers = const [];
  List<CookActiveOffer> get activeOffers => _activeOffers;

  List<Order> _completedOffers = const [];
  List<Order> get completedOffers => _completedOffers;

  Order? _activeOrder;
  Order? get activeOrder => _activeOrder;

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollIncomingRequests();
      _pollActiveOffers();
      _pollActiveOrder();
    });
  }

  Future<void> _pollIncomingRequests() async {
    if (!_isAvailable) return;

    try {
      _incomingRequests = await cookRequestRepository.fetchActiveRequests(
        maxRadiusKm: 10,
      );
      _incomingRequests =
          _incomingRequests
              .where((request) => !_ignoredRequestIds.contains(request.id))
              .toList();
      _hasIncomingRequests = _incomingRequests.isNotEmpty;
      notifyListeners();
    } catch (_) {}
  }

  void ignoreRequest(String requestId) {
    _ignoredRequestIds.add(requestId);
    _incomingRequests =
        _incomingRequests.where((request) => request.id != requestId).toList();
    _hasIncomingRequests = _incomingRequests.isNotEmpty;
    notifyListeners();
  }

  Future<void> _pollActiveOrder() async {
    try {
      final order = await orderRepository.fetchActiveOrder();
      if (order?.id != _activeOrder?.id) {
        _activeOrder = order;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _pollActiveOffers() async {
    try {
      _activeOffers = await offerRepository.fetchActiveCookOffers();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshActiveOffers() async {
    await _pollActiveOffers();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        publicationRepository.fetchOwnPublications(),
        publicationRepository.fetchCookAvailability(),
        orderRepository.fetchCompletedCookOrders(),
      ]);
      _publications = results[0] as List<DishPublication>;
      _isAvailable = results[1] as bool;
      _completedOffers = results[2] as List<Order>;
      await _pollActiveOrder();
      await _pollActiveOffers();
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
                          latitude: latitude,
                          longitude: longitude,
                          zoneLabel: zoneLabel,
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

  Future<DishPublication?> addPublicationPhoto({
    required DishPublication publication,
    required File imageFile,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final position = publication.photos.length + 1;
      final storagePath = await publicationRepository.uploadPhoto(
        imageFile,
        position: position,
      );
      await publicationRepository.addPublicationPhoto(
        publicationId: publication.id,
        storagePath: storagePath,
        position: position,
      );
      final updated = publication.copyWith(
        photos: [
          ...publication.photos,
          DishPublicationPhoto(
            storagePath: storagePath,
            publicUrl: publicationRepository.photoPublicUrl(storagePath),
            position: position,
          ),
        ],
      );
      _replacePublication(updated);
      return updated;
    } catch (_) {
      _error = 'No se pudo agregar la foto.';
      notifyListeners();
      return null;
    }
  }

  Future<DishPublication?> deletePublicationPhoto({
    required DishPublication publication,
    required DishPublicationPhoto photo,
  }) async {
    if (publication.photos.length <= 1) {
      _error = 'La publicación debe conservar al menos una foto.';
      notifyListeners();
      return null;
    }

    _error = null;
    notifyListeners();

    try {
      await publicationRepository.deletePublicationPhoto(
        publicationId: publication.id,
        storagePath: photo.storagePath,
      );
      final updatedPhotos =
          publication.photos
              .where((item) => item.storagePath != photo.storagePath)
              .toList()
              .asMap()
              .entries
              .map(
                (entry) => DishPublicationPhoto(
                  id: entry.value.id,
                  storagePath: entry.value.storagePath,
                  publicUrl: entry.value.publicUrl,
                  position: entry.key + 1,
                ),
              )
              .toList();
      final updated = publication.copyWith(photos: updatedPhotos);
      _replacePublication(updated);
      return updated;
    } catch (_) {
      _error = 'No se pudo eliminar la foto.';
      notifyListeners();
      return null;
    }
  }

  Future<DishPublication?> reorderPublicationPhotos({
    required DishPublication publication,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= publication.photos.length ||
        newIndex >= publication.photos.length) {
      return publication;
    }

    final reordered = [...publication.photos];
    final photo = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, photo);

    _error = null;
    notifyListeners();

    try {
      await publicationRepository.reorderPublicationPhotos(
        publicationId: publication.id,
        orderedStoragePaths: reordered.map((item) => item.storagePath).toList(),
      );
      final updated = publication.copyWith(
        photos:
            reordered
                .asMap()
                .entries
                .map(
                  (entry) => DishPublicationPhoto(
                    id: entry.value.id,
                    storagePath: entry.value.storagePath,
                    publicUrl: entry.value.publicUrl,
                    position: entry.key + 1,
                  ),
                )
                .toList(),
      );
      _replacePublication(updated);
      return updated;
    } catch (_) {
      _error = 'No se pudo reordenar la foto.';
      notifyListeners();
      return null;
    }
  }

  void _replacePublication(DishPublication publication) {
    _publications =
        _publications
            .map((item) => item.id == publication.id ? publication : item)
            .toList();
    notifyListeners();
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
