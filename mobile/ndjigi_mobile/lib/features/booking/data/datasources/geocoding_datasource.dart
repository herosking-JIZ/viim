import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingDataSource {
  final Dio dio;
  final String apiKey = "TA_CLE_GOOGLE";

  GeocodingDataSource(this.dio);

  Future<LatLng> getCoordsFromAddress(String address) async {
    final response = await dio.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {'address': address, 'key': apiKey},
    );

    final results = response.data['results'] as List;
    if (results.isNotEmpty) {
      final location = results[0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    throw Exception("Adresse introuvable");
  }
}