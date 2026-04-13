import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_position.freezed.dart';

@freezed
class VehiclePosition with _$VehiclePosition {
  const factory VehiclePosition({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double? heading, // Cap/Direction
    double? speed,
    required DateTime timestamp,
  }) = _VehiclePosition;
}