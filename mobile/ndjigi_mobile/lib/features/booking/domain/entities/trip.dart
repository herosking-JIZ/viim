import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';

@freezed
class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String passengerId,
    required String pickupAddress,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    @Default('en_attente') String status, // en_attente, accepte, en_cours, termine, annule
    required String typeTrajet, // immediat, programme, covoiturage
    double? fare,
    DateTime? scheduledAt,
    String? driverId,
  }) = _Trip;
}