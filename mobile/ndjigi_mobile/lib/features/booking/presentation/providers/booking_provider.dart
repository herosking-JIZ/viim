// lib/features/booking/presentation/providers/booking_provider.dart

class BookingNotifier extends StateNotifier<BookingState> {
  final Ref ref;

  BookingNotifier(this.ref) : super(BookingState());

  Future<void> requestImmediateTrip({
    required String destination,
    required double lat,
    required double lng,
  }) async {
    // 1. Passer en mode "Recherche"
    state = BookingState(status: BookingStatus.searching);

    // 2. Préparer les données (Contrat API)
    final tripData = {
      'type_trajet': 'immediat',
      'adresse_arrivee': destination,
      'coordonnees_arrivee': {'lat': lat, 'lng': lng},
      'id_utilisateur': ref.read(authProvider).user?.id,
    };

    // 3. Envoyer via Socket.io
    final socket = ref.read(dioProvider); // Ton instance socket
    socket.emit('trip:request', tripData);

    // 4. Écouter la réponse du serveur (Si un chauffeur accepte)
    socket.on('trip:accepted', (data) {
      final trip = TripModel.fromJson(data).toEntity();
      state = BookingState(status: BookingStatus.confirmed, currentTrip: trip);

      // Ici tu pourras naviguer vers l'écran de suivi
    });
  }
}