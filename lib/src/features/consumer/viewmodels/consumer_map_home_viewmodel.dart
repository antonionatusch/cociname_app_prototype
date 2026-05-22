import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../core/services/permission_service.dart';
import '../../offers/models/cook_offer.dart';
import '../../offers/repositories/offer_repository.dart';
import '../../orders/models/order.dart';
import '../../orders/repositories/order_repository.dart';
import '../models/available_cook_marker.dart';
import '../repositories/consumer_request_repository.dart';

class ConsumerCookMarker {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  bool get isAvailable => true;

  ConsumerCookMarker({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  latlong.LatLng get latLng => latlong.LatLng(latitude, longitude);
}

class ConsumerMapHomeViewModel extends ChangeNotifier {
  ConsumerMapHomeViewModel({
    required this.permissionService,
    required this.requestRepository,
    required this.offerRepository,
    required this.orderRepository,
  });

  final PermissionService permissionService;
  final ConsumerRequestRepository requestRepository;
  final OfferRepository offerRepository;
  final OrderRepository orderRepository;

  static const double _defaultLat = -17.7833;
  static const double _defaultLng = -63.1821;

  double _latitude = _defaultLat;
  double _longitude = _defaultLng;
  bool _isLoadingLocation = false;
  bool _showMarkers = false;
  bool _showCookSheet = false;
  String? _selectedCookId;
  String? _error;
  Order? _activeOrder;

  final List<ConsumerCookMarker> _cooks = [];
  List<ConsumerCookMarker> get cooks => List.unmodifiable(_cooks);

  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get showMarkers => _showMarkers;
  bool get showCookSheet => _showCookSheet;
  String? get selectedCookId => _selectedCookId;
  String? get error => _error;
  Order? get activeOrder => _activeOrder;

  latlong.LatLng get currentLatLng => latlong.LatLng(_latitude, _longitude);

  Future<void> init() async {
    await _getCurrentLocation();
    await _restoreActiveSession();
    await _loadAvailableCooks();
    _startMarkerPolling();
    Future.delayed(const Duration(milliseconds: 1000), () {
      _showMarkers = true;
      notifyListeners();
    });
  }

  Future<void> _restoreActiveSession() async {
    try {
      _activeOrder = await orderRepository.fetchActiveOrder();
      if (_activeOrder != null) {
        notifyListeners();
        return;
      }

      final activeRequests = await requestRepository.fetchActiveRequest();
      if (activeRequests.isEmpty) return;

      final request = activeRequests.first;
      _activeRequestId = request.id;
      _visibleSearchRadiusKm = request.currentRadiusKm;
      _maxSearchRadiusKm = request.maxRadiusKm;
      _searchStatus =
          request.status == 'matched'
              ? 'Solicitud emparejada. Revisando pedido...'
              : 'Buscando cocineros en ${_visibleSearchRadiusKm.toStringAsFixed(1)} km...';
      _receivedOffers = await offerRepository.fetchOffersForRequest(request.id);
      if (_receivedOffers.isNotEmpty) {
        _searchStatus = '${_receivedOffers.length} oferta(s) recibida(s)';
      } else {
        _startRadiusExpansion();
      }
      _startOfferPolling();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    final permission = await permissionService.requestLocation();
    if (permission != AppPermissionStatus.granted &&
        permission != AppPermissionStatus.limited) {
      return;
    }

    _isLoadingLocation = true;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (_) {}

    _isLoadingLocation = false;
    notifyListeners();
  }

  Future<void> _loadAvailableCooks() async {
    try {
      final markers = await requestRepository.fetchAvailableCookMarkers();
      _cooks
        ..clear()
        ..addAll(markers.map(_cookMarkerFromAvailable));
    } catch (_) {
      _cooks.clear();
    }
    notifyListeners();
  }

  ConsumerCookMarker _cookMarkerFromAvailable(AvailableCookMarker marker) {
    return ConsumerCookMarker(
      id: marker.id,
      name: marker.name,
      latitude: marker.latitude,
      longitude: marker.longitude,
    );
  }

  void onCookTapped(String cookId) {
    _selectedCookId = cookId;
    _showCookSheet = true;
    notifyListeners();
  }

  void dismissCookSheet() {
    _showCookSheet = false;
    _selectedCookId = null;
    notifyListeners();
  }

  String? getSelectedCookName() {
    if (_selectedCookId == null) return null;
    final cook = _cooks.where((c) => c.id == _selectedCookId).firstOrNull;
    return cook?.name;
  }

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _activeRequestId;
  String? get activeRequestId => _activeRequestId;

  String _searchStatus = '';
  String get searchStatus => _searchStatus;

  double _visibleSearchRadiusKm = 1;
  double get visibleSearchRadiusKm => _visibleSearchRadiusKm;

  double _maxSearchRadiusKm = 4;
  double get maxSearchRadiusKm => _maxSearchRadiusKm;

  Future<String?> createSearchRequest({
    required String query,
    required double budget,
    required int requestedQuantity,
    required double maxRadius,
    List<String> allergenFilters = const [],
  }) async {
    _isSearching = true;
    _searchStatus = 'Buscando cocineros cerca...';
    _visibleSearchRadiusKm = 1;
    _maxSearchRadiusKm = maxRadius;
    _error = null;
    notifyListeners();

    try {
      final requestId = await requestRepository.createRequest(
        queryText: query,
        targetPrice: budget,
        requestedQuantity: requestedQuantity,
        allergenFilters: allergenFilters,
        maxRadiusKm: maxRadius,
        currentRadiusKm: 1,
        latitude: _latitude,
        longitude: _longitude,
      );
      _activeRequestId = requestId;
      _receivedOffers = const [];
      _searchStatus =
          'Buscando cocineros en ${_visibleSearchRadiusKm.toStringAsFixed(1)} km...';
      _startRadiusExpansion();
      _startOfferPolling();
      return requestId;
    } catch (e) {
      _error = 'No se pudo crear la solicitud: $e';
      _searchStatus = '';
      return null;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> cancelSearch() async {
    if (_activeRequestId != null) {
      try {
        await requestRepository.cancelRequest(_activeRequestId!);
        _offerPollTimer?.cancel();
        _radiusTimer?.cancel();
        _activeRequestId = null;
        _receivedOffers = const [];
        _searchStatus = '';
        _visibleSearchRadiusKm = 1;
        _error = null;
        notifyListeners();
      } catch (e) {
        _error = 'No se pudo cancelar la búsqueda: $e';
        notifyListeners();
      }
    }
  }

  List<CookOffer> _receivedOffers = const [];
  List<CookOffer> get receivedOffers => _receivedOffers;

  bool get hasOffers => _receivedOffers.isNotEmpty;

  Timer? _offerPollTimer;
  Timer? _markerPollTimer;
  Timer? _radiusTimer;

  void _startRadiusExpansion() {
    _radiusTimer?.cancel();
    _radiusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_activeRequestId == null || _receivedOffers.isNotEmpty) {
        _radiusTimer?.cancel();
        return;
      }
      final nextRadius = (_visibleSearchRadiusKm + 0.75).clamp(
        1,
        _maxSearchRadiusKm,
      );
      if (nextRadius == _visibleSearchRadiusKm) return;
      _visibleSearchRadiusKm = nextRadius.toDouble();
      _searchStatus =
          'Buscando cocineros en ${_visibleSearchRadiusKm.toStringAsFixed(1)} km...';
      notifyListeners();
    });
  }

  void _startOfferPolling() {
    _offerPollTimer?.cancel();
    if (_activeRequestId == null) return;

    _offerPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollOffers();
    });
  }

  void _startMarkerPolling() {
    _markerPollTimer?.cancel();
    _markerPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadAvailableCooks();
    });
  }

  Future<void> _pollOffers() async {
    if (_activeRequestId == null) return;

    try {
      _receivedOffers = await offerRepository.fetchOffersForRequest(
        _activeRequestId!,
      );
      if (_receivedOffers.isNotEmpty) {
        _searchStatus = '${_receivedOffers.length} oferta(s) recibida(s)';
        _radiusTimer?.cancel();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<Order?> acceptOffer(String offerId) async {
    _offerPollTimer?.cancel();
    _radiusTimer?.cancel();
    try {
      await orderRepository.acceptOffer(offerId);
      final order = await orderRepository.fetchActiveOrder();
      _activeOrder = order;
      _activeRequestId = null;
      _receivedOffers = const [];
      await _loadAvailableCooks();
      return order;
    } catch (e) {
      _error = 'Error al aceptar oferta: $e';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _offerPollTimer?.cancel();
    _markerPollTimer?.cancel();
    _radiusTimer?.cancel();
    super.dispose();
  }
}
