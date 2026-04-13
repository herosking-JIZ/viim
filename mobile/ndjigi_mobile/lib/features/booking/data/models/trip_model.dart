import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/trip.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

@freezed
class TripModel with _$TripModel {
  const factory TripModel({
    @JsonKey(name: 'id_trajet') required String id,
    @JsonKey(name: 'adresse_depart') required String pickupAddress,
    @JsonKey(name: 'adresse_arrivee') required String destinationAddress,
    @JsonKey(name: 'tarif_final') double? fare,
    required String statut,
    @JsonKey(name: 'type_trajet') required String typeTrajet,
    @JsonKey(name: 'id_utilisateur') required String passengerId,
    // Coordonnées stockées en JSON dans ton schéma Prisma
    Map<String, dynamic>? coordonnees_arrivee,
  }) = _TripModel;

  factory TripModel.fromJson(Map<String, dynamic> json) => _$TripModelFromJson(json);

  Trip toEntity() => Trip(
    id: id,
    passengerId: passengerId,
    pickupAddress: pickupAddress,
    destinationAddress: destinationAddress,
    destinationLat: coordonnees_arrivee?['lat'] ?? 0.0,
    destinationLng: coordonnees_arrivee?['lng'] ?? 0.0,
    status: statut,
    typeTrajet: typeTrajet,
    fare: fare,
  );
}