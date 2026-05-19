import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/permission_service.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class LocationResult {
  const LocationResult._({this.position, this.address, this.failure});

  const LocationResult.success(Position position, {String? address})
    : this._(position: position, address: address);

  const LocationResult.failure(LocationFailure failure)
    : this._(failure: failure);

  final Position? position;
  final String? address;
  final LocationFailure? failure;
}

class LocationService {
  LocationService({required this.permissionService});

  final PermissionService permissionService;

  Future<LocationResult> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    }

    final permission = await permissionService.requestLocation();
    switch (permission) {
      case AppPermissionStatus.granted:
      case AppPermissionStatus.limited:
        break;
      case AppPermissionStatus.permanentlyDenied:
      case AppPermissionStatus.restricted:
        return const LocationResult.failure(
          LocationFailure.permissionPermanentlyDenied,
        );
      case AppPermissionStatus.denied:
        return const LocationResult.failure(LocationFailure.permissionDenied);
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final address = await _resolveAddress(position);
      return LocationResult.success(position, address: address);
    } catch (e) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }

  Future<String?> _resolveAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      return _formatPlacemark(placemarks.first);
    } catch (_) {
      return null;
    }
  }

  String? _formatPlacemark(Placemark place) {
    final street = _clean(place.street);
    if (street != null) return street;

    final route = _clean(place.thoroughfare);
    final number = _clean(place.subThoroughfare);
    if (route != null && number != null) return '$route $number';
    if (route != null) return route;

    final name = _clean(place.name);
    if (name != null) return name;

    final parts =
        [
          _clean(place.subLocality),
          _clean(place.locality),
          _clean(place.administrativeArea),
        ].whereType<String>().toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
