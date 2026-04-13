import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/tracking_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    // Démarrer le tracking au chargement
    Future.microtask(() => ref.read(trackingProvider.notifier).startTracking());
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);

    return Scaffold(
      body: trackingState.userPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            trackingState.userPosition!.latitude,
            trackingState.userPosition!.longitude,
          ),
          zoom: 15,
        ),
        markers: trackingState.markers,
        onMapCreated: (controller) => _controller = controller,
        myLocationEnabled: true,
      ),
    );
  }
}