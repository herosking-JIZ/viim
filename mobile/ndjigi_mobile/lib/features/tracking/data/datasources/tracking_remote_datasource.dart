import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../domain/entities/vehicle_position.dart';

abstract class TrackingRemoteDataSource {
  void connect(String token);
  void sendLocation(VehiclePosition position);
  Stream<VehiclePosition> getNearbyVehicles();
  void disconnect();
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  late IO.Socket socket;

  @override
  void connect(String token) {
    socket = IO.io('http://TON_IP_SERVEUR:3000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .build()
    );

    socket.onConnect((_) => print('Connecté au serveur de tracking'));
  }

  @override
  void sendLocation(VehiclePosition position) {
    socket.emit('update_location', {
      'lat': position.latitude,
      'lng': position.longitude,
      'heading': position.heading,
    });
  }

  @override
  Stream<VehiclePosition> getNearbyVehicles() {
    // Transforme les événements socket en Stream pour Riverpod
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      // Logique de réception des positions des autres véhicules
      // socket.on('nearby_vehicles', (data) => ...);
      throw UnimplementedError("Interface Stream via Socket");
    });
  }

  @override
  void disconnect() => socket.disconnect();
}