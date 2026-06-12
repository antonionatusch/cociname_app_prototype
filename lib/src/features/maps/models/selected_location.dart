enum LocationSource { gps, search, manualPin }

class SelectedLocation {
  final double latitude;
  final double longitude;
  final String addressLabel;
  final LocationSource source;

  const SelectedLocation({
    required this.latitude,
    required this.longitude,
    required this.addressLabel,
    required this.source,
  });
}
