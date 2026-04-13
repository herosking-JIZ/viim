import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/trip_model.dart';

abstract class BookingRemoteDataSource {
  void requestTrip(TripModel trip);
  Stream<String> watchTripStatus(String tripId);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final IO.Socket socket; // Injecté via Riverpod depuis le core

  BookingRemoteDataSourceImpl(this.socket);

  @override
  void requestTrip(TripModel trip) {
    // Émission de la demande vers le backend Node.js
    socket.emit('trip:request', trip.toJson());
  }

  @override
  Stream<String> watchTripStatus(String tripId) {
    // Écoute les changements de statut envoyés par le serveur
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) {
      // Le backend émettra sur 'trip:status:ID'
      return "Statut mis à jour";
    });
  }
}