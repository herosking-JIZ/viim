import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripTrackingState {
  final LatLng? driverPosition;
  final Set<Polyline> polylines;
  final String eta; // Temps d'arrivée estimé

  TripTrackingState({
    this.driverPosition,
    this.polylines = const {},
    this.eta = "-- min",
  });
}

class TripTrackingNotifier extends StateNotifier<TripTrackingState> {
  TripTrackingNotifier() : super(TripTrackingState());

  // Appelé quand le socket reçoit 'driver:location_update'
  void updateDriverLocation(double lat, double lng) {
    state = TripTrackingState(
      driverPosition: LatLng(lat, lng),
      polylines: state.polylines,
      eta: state.eta,
    );
  }

  // Logique pour tracer la ligne entre le chauffeur et la destination
  void setPolylines(List<LatLng> points) {
    final polyline = Polyline(
      polylineId: const PolylineId("route"),
      points: points,
      color: Colors.blue,
      width: 5,
    );
    state = TripTrackingState(
      driverPosition: state.driverPosition,
      polylines: {polyline},
      eta: state.eta,
    );
  }
}

final tripTrackingProvider = StateNotifierProvider<TripTrackingNotifier, TripTrackingState>((ref) => TripTrackingNotifier());