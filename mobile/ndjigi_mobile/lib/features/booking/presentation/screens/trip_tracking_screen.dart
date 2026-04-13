import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/trip_tracking_provider.dart';

class TripTrackingScreen extends ConsumerWidget {
  const TripTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(tripTrackingProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. La Carte
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(12.37, -1.53), zoom: 14),
            polylines: trackingState.polylines,
            markers: {
              if (trackingState.driverPosition != null)
                Marker(
                  markerId: const MarkerId("driver"),
                  position: trackingState.driverPosition!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  infoWindow: const InfoWindow(title: "Votre chauffeur"),
                ),
            },
          ),

          // 2. Overlay d'infos (Carte flottante en bas)
          Positioned(
            bottom: 20, left: 10, right: 10,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text("Arrivée dans 5 min"),
                      subtitle: const Text("Toyota Corolla - AB-123-CD"),
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () {},
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {}, // Bouton SOS
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("BOUTON SOS", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}