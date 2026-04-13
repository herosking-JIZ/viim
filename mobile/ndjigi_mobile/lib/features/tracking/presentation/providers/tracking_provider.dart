import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingState {
  final Position? userPosition;
  final Set<Marker> markers;
  final bool isTracking;

  TrackingState({this.userPosition, this.markers = const {}, this.isTracking = false});
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(TrackingState());

  Future<void> startTracking() async {
    // 1. Vérifier les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 2. Écouter les changements de position
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      ),
    ).listen((Position position) {
      state = TrackingState(
        userPosition: position,
        isTracking: true,
        markers: {
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: "Ma position"),
          )
        },
      );

      // TODO: Appeler le repository pour envoyer la position au socket
    });
  }
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});