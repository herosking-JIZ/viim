import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_provider.dart';

class DestinationSelectionScreen extends ConsumerWidget {
  final TextEditingController _destinationController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Où allez-vous ?")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                icon: Icon(Icons.location_on, color: Colors.red),
                hintText: "Saisissez votre destination",
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () {
                // Déclenche la recherche et l'estimation
                ref.read(bookingProvider.notifier).createImmediateTrip(
                    _destinationController.text,
                    0.0, 0.0 // Les coords seront calculées par le datasource
                );
                // Naviguer vers l'écran "Searching" (Étape 4)
              },
              child: const Text("CONFIRMER LA DESTINATION"),
            ),
          ],
        ),
      ),
    );
  }
}