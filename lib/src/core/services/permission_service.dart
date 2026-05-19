import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

enum AppPermissionStatus {
  granted,
  limited,
  denied,
  permanentlyDenied,
  restricted,
}

class PermissionService {
  Future<AppPermissionStatus> requestLocation() async {
    return _mapStatus(await permissions.Permission.locationWhenInUse.request());
  }

  Future<AppPermissionStatus> requestCamera() async {
    return _mapStatus(await permissions.Permission.camera.request());
  }

  Future<AppPermissionStatus> requestPhotos() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final photosStatus = await permissions.Permission.photos.request();
      if (photosStatus.isGranted ||
          photosStatus.isLimited ||
          photosStatus.isPermanentlyDenied) {
        return _mapStatus(photosStatus);
      }

      return _mapStatus(await permissions.Permission.storage.request());
    }

    return _mapStatus(await permissions.Permission.photos.request());
  }

  Future<bool> openAppSettings() {
    return permissions.openAppSettings();
  }

  AppPermissionStatus _mapStatus(permissions.PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isLimited) return AppPermissionStatus.limited;
    if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return AppPermissionStatus.restricted;
    return AppPermissionStatus.denied;
  }
}
