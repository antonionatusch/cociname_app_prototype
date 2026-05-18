import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await Permission.location.status;
    if (!hasPermission.isGranted) {
      final granted = await requestPermission();
      if (!granted) return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }
}
