import 'package:latlong2/latlong.dart' as latlong;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../consumer/models/consumer_request.dart';

class CookRequestRepository {
  CookRequestRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ConsumerRequest>> fetchActiveRequests({
    double? cookLatitude,
    double? cookLongitude,
    double? maxRadiusKm,
  }) async {
    final response = await _client.rpc(
      'get_active_consumer_requests_for_cook',
      params: {'p_limit': 20},
    );

    final requests =
        (response as List<dynamic>)
            .map(
              (item) => ConsumerRequest.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

    if (cookLatitude == null || cookLongitude == null || maxRadiusKm == null) {
      return requests;
    }

    requests.removeWhere((request) {
      if (request.latitude == null || request.longitude == null) return true;

      final distance = latlong.Distance().as(
        latlong.LengthUnit.Kilometer,
        latlong.LatLng(cookLatitude, cookLongitude),
        latlong.LatLng(request.latitude!, request.longitude!),
      );

      return distance > maxRadiusKm;
    });

    final maxRequestRadius =
        requests.isEmpty
            ? double.infinity
            : requests
                .map((r) => r.maxRadiusKm)
                .reduce((a, b) => a > b ? a : b);

    requests.removeWhere((request) {
      final distance = latlong.Distance().as(
        latlong.LengthUnit.Kilometer,
        latlong.LatLng(cookLatitude, cookLongitude),
        latlong.LatLng(
          request.latitude ?? cookLatitude,
          request.longitude ?? cookLongitude,
        ),
      );
      return distance > maxRequestRadius;
    });

    return requests;
  }
}
