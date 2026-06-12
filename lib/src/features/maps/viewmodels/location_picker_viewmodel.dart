import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../core/services/permission_service.dart';
import '../models/selected_location.dart';

class LocationPickerViewModel extends ChangeNotifier {
  LocationPickerViewModel({required this.permissionService});

  final PermissionService permissionService;

  static const double _fallbackLat = -17.7833;
  static const double _fallbackLng = -63.1821;
  static const String _fallbackLabel = 'Santa Cruz, Bolivia';

  double _latitude = _fallbackLat;
  double _longitude = _fallbackLng;
  String _addressLabel = _fallbackLabel;
  bool _isLoadingLocation = false;
  bool _isResolvingAddress = false;
  String? _error;

  double get latitude => _latitude;
  double get longitude => _longitude;
  String get addressLabel => _addressLabel;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isResolvingAddress => _isResolvingAddress;
  String? get error => _error;

  latlong.LatLng get latLng => latlong.LatLng(_latitude, _longitude);

  Future<void> init() async {
    await getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Activa la ubicación del dispositivo';
      notifyListeners();
      return;
    }

    final permission = await permissionService.requestLocation();
    if (permission != AppPermissionStatus.granted &&
        permission != AppPermissionStatus.limited) {
      _error = 'Permiso de ubicación denegado. Usa el pin o la búsqueda.';
      notifyListeners();
      return;
    }

    _isLoadingLocation = true;
    _error = null;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
      _resolveAddress(position.latitude, position.longitude);
    } catch (_) {
      _error = 'No se pudo obtener la ubicación';
    }

    _isLoadingLocation = false;
    notifyListeners();
  }

  void movePin(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    _error = null;
    notifyListeners();
    _resolveAddress(lat, lng);
  }

  Future<void> searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    _isResolvingAddress = true;
    _error = null;
    notifyListeners();

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        _error = 'No se encontró la dirección. Mueve el pin en el mapa.';
        _isResolvingAddress = false;
        notifyListeners();
        return;
      }

      final location = locations.first;
      _latitude = location.latitude;
      _longitude = location.longitude;
      _resolveAddress(location.latitude, location.longitude);
    } catch (_) {
      _error = 'Error al buscar. Mueve el pin en el mapa.';
    }

    _isResolvingAddress = false;
    notifyListeners();
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    _addressLabel = _formatCoords(lat, lng);
    notifyListeners();

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        _addressLabel = _formatPlacemark(placemarks.first);
      }
    } catch (_) {}

    notifyListeners();
  }

  String _formatPlacemark(Placemark place) {
    final street = _clean(place.street);
    if (street != null) return street;

    final route = _clean(place.thoroughfare);
    final number = _clean(place.subThoroughfare);
    if (route != null && number != null) return '$route $number';
    if (route != null) return route;

    final name = _clean(place.name);
    if (name != null) return name;

    final parts = [
      _clean(place.subLocality),
      _clean(place.locality),
      _clean(place.administrativeArea),
    ].whereType<String>().toList();
    if (parts.isEmpty) return _formatCoords(_latitude, _longitude);
    return parts.join(', ');
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _formatCoords(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  SelectedLocation get selectedLocation => SelectedLocation(
    latitude: _latitude,
    longitude: _longitude,
    addressLabel: _addressLabel,
    source: LocationSource.manualPin,
  );
}
