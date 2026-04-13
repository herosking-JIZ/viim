import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_provider.dart';

class SearchingDriverScreen extends ConsumerWidget {
  const SearchingDriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(), // Animation de recherche
            const SizedBox(height: 20),
            Text(
              "Recherche de chauffeur en cours...",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text("Nous cherchons le chauffeur le plus proche pour vous."),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () { /* Logique d'annulation */ },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Annuler la recherche"),
            )
          ],
        ),
      ),
    );
  }
}