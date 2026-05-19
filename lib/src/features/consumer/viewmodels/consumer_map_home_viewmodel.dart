import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../core/services/permission_service.dart';
import '../../offers/models/cook_offer.dart';
import '../../offers/repositories/offer_repository.dart';
import '../../orders/models/order.dart';
import '../../orders/repositories/order_repository.dart';
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

  final List<ConsumerCookMarker> _cooks = [];
  List<ConsumerCookMarker> get cooks => List.unmodifiable(_cooks);

  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get showMarkers => _showMarkers;
  bool get showCookSheet => _showCookSheet;
  String? get selectedCookId => _selectedCookId;
  String? get error => _error;

  latlong.LatLng get currentLatLng => latlong.LatLng(_latitude, _longitude);

  Future<void> init() async {
    await _getCurrentLocation();
    _loadDemoCooks();
    Future.delayed(const Duration(milliseconds: 1000), () {
      _showMarkers = true;
      notifyListeners();
    });
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (_) {}

    _isLoadingLocation = false;
    notifyListeners();
  }

  void _loadDemoCooks() {
    _cooks.addAll([
      ConsumerCookMarker(
        id: 'cook-1',
        name: 'Doña Maria',
        latitude: _latitude + 0.005,
        longitude: _longitude - 0.008,
      ),
      ConsumerCookMarker(
        id: 'cook-2',
        name: 'Don José',
        latitude: _latitude - 0.003,
        longitude: _longitude + 0.01,
      ),
      ConsumerCookMarker(
        id: 'cook-3',
        name: 'Cocina Doña Ana',
        latitude: _latitude + 0.008,
        longitude: _longitude + 0.004,
      ),
    ]);
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

  Future<String?> createSearchRequest({
    required String query,
    required double budget,
    required double maxRadius,
    List<String> allergenFilters = const [],
  }) async {
    _isSearching = true;
    _searchStatus = 'Buscando cocineros cerca...';
    _error = null;
    notifyListeners();

    try {
      final requestId = await requestRepository.createRequest(
        queryText: query,
        targetPrice: budget,
        allergenFilters: allergenFilters,
        maxRadiusKm: maxRadius,
        currentRadiusKm: 1,
        latitude: _latitude,
        longitude: _longitude,
      );
      _activeRequestId = requestId;
      _searchStatus = 'Solicitud creada. Esperando ofertas...';
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
      await requestRepository.cancelRequest(_activeRequestId!);
      _activeRequestId = null;
      _searchStatus = '';
      notifyListeners();
    }
  }

  List<CookOffer> _receivedOffers = const [];
  List<CookOffer> get receivedOffers => _receivedOffers;

  bool get hasOffers => _receivedOffers.isNotEmpty;

  Timer? _offerPollTimer;

  void _startOfferPolling() {
    _offerPollTimer?.cancel();
    if (_activeRequestId == null) return;

    _offerPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollOffers();
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
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<Order?> acceptOffer(String offerId) async {
    try {
      await orderRepository.acceptOffer(offerId);
      _offerPollTimer?.cancel();
      final order = await orderRepository.fetchActiveOrder();
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
    super.dispose();
  }
}

