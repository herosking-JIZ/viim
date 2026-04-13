// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TripModelImpl _$$TripModelImplFromJson(Map<String, dynamic> json) =>
    _$TripModelImpl(
      id: json['id_trajet'] as String,
      pickupAddress: json['adresse_depart'] as String,
      destinationAddress: json['adresse_arrivee'] as String,
      fare: (json['tarif_final'] as num?)?.toDouble(),
      statut: json['statut'] as String,
      typeTrajet: json['type_trajet'] as String,
      passengerId: json['id_utilisateur'] as String,
      coordonnees_arrivee: json['coordonnees_arrivee'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TripModelImplToJson(_$TripModelImpl instance) =>
    <String, dynamic>{
      'id_trajet': instance.id,
      'adresse_depart': instance.pickupAddress,
      'adresse_arrivee': instance.destinationAddress,
      'tarif_final': instance.fare,
      'statut': instance.statut,
      'type_trajet': instance.typeTrajet,
      'id_utilisateur': instance.passengerId,
      'coordonnees_arrivee': instance.coordonnees_arrivee,
    };
