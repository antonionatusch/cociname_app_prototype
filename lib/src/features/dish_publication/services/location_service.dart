import 'package:geolocator/geolocator.dart';

import '../../../core/services/permission_service.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class LocationResult {
  const LocationResult._({this.position, this.failure});

  const LocationResult.success(Position position) : this._(position: position);

  const LocationResult.failure(LocationFailure failure)
    : this._(failure: failure);

  final Position? position;
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
      return LocationResult.success(position);
    } catch (e) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }
}
