// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Trip {
  String get id => throw _privateConstructorUsedError;
  String get passengerId => throw _privateConstructorUsedError;
  String get pickupAddress => throw _privateConstructorUsedError;
  String get destinationAddress => throw _privateConstructorUsedError;
  double get destinationLat => throw _privateConstructorUsedError;
  double get destinationLng => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // en_attente, accepte, en_cours, termine, annule
  String get typeTrajet =>
      throw _privateConstructorUsedError; // immediat, programme, covoiturage
  double? get fare => throw _privateConstructorUsedError;
  DateTime? get scheduledAt => throw _privateConstructorUsedError;
  String? get driverId => throw _privateConstructorUsedError;

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TripCopyWith<Trip> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripCopyWith<$Res> {
  factory $TripCopyWith(Trip value, $Res Function(Trip) then) =
      _$TripCopyWithImpl<$Res, Trip>;
  @useResult
  $Res call(
      {String id,
      String passengerId,
      String pickupAddress,
      String destinationAddress,
      double destinationLat,
      double destinationLng,
      String status,
      String typeTrajet,
      double? fare,
      DateTime? scheduledAt,
      String? driverId});
}

/// @nodoc
class _$TripCopyWithImpl<$Res, $Val extends Trip>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? passengerId = null,
    Object? pickupAddress = null,
    Object? destinationAddress = null,
    Object? destinationLat = null,
    Object? destinationLng = null,
    Object? status = null,
    Object? typeTrajet = null,
    Object? fare = freezed,
    Object? scheduledAt = freezed,
    Object? driverId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      passengerId: null == passengerId
          ? _value.passengerId
          : passengerId // ignore: cast_nullable_to_non_nullable
              as String,
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      destinationAddress: null == destinationAddress
          ? _value.destinationAddress
          : destinationAddress // ignore: cast_nullable_to_non_nullable
              as String,
      destinationLat: null == destinationLat
          ? _value.destinationLat
          : destinationLat // ignore: cast_nullable_to_non_nullable
              as double,
      destinationLng: null == destinationLng
          ? _value.destinationLng
          : destinationLng // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      typeTrajet: null == typeTrajet
          ? _value.typeTrajet
          : typeTrajet // ignore: cast_nullable_to_non_nullable
              as String,
      fare: freezed == fare
          ? _value.fare
          : fare // ignore: cast_nullable_to_non_nullable
              as double?,
      scheduledAt: freezed == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      driverId: freezed == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripImplCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$$TripImplCopyWith(
          _$TripImpl value, $Res Function(_$TripImpl) then) =
      __$$TripImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String passengerId,
      String pickupAddress,
      String destinationAddress,
      double destinationLat,
      double destinationLng,
      String status,
      String typeTrajet,
      double? fare,
      DateTime? scheduledAt,
      String? driverId});
}

/// @nodoc
class __$$TripImplCopyWithImpl<$Res>
    extends _$TripCopyWithImpl<$Res, _$TripImpl>
    implements _$$TripImplCopyWith<$Res> {
  __$$TripImplCopyWithImpl(_$TripImpl _value, $Res Function(_$TripImpl) _then)
      : super(_value, _then);

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? passengerId = null,
    Object? pickupAddress = null,
    Object? destinationAddress = null,
    Object? destinationLat = null,
    Object? destinationLng = null,
    Object? status = null,
    Object? typeTrajet = null,
    Object? fare = freezed,
    Object? scheduledAt = freezed,
    Object? driverId = freezed,
  }) {
    return _then(_$TripImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      passengerId: null == passengerId
          ? _value.passengerId
          : passengerId // ignore: cast_nullable_to_non_nullable
              as String,
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      destinationAddress: null == destinationAddress
          ? _value.destinationAddress
          : destinationAddress // ignore: cast_nullable_to_non_nullable
              as String,
      destinationLat: null == destinationLat
          ? _value.destinationLat
          : destinationLat // ignore: cast_nullable_to_non_nullable
              as double,
      destinationLng: null == destinationLng
          ? _value.destinationLng
          : destinationLng // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      typeTrajet: null == typeTrajet
          ? _value.typeTrajet
          : typeTrajet // ignore: cast_nullable_to_non_nullable
              as String,
      fare: freezed == fare
          ? _value.fare
          : fare // ignore: cast_nullable_to_non_nullable
              as double?,
      scheduledAt: freezed == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      driverId: freezed == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$TripImpl implements _Trip {
  const _$TripImpl(
      {required this.id,
      required this.passengerId,
      required this.pickupAddress,
      required this.destinationAddress,
      required this.destinationLat,
      required this.destinationLng,
      this.status = 'en_attente',
      required this.typeTrajet,
      this.fare,
      this.scheduledAt,
      this.driverId});

  @override
  final String id;
  @override
  final String passengerId;
  @override
  final String pickupAddress;
  @override
  final String destinationAddress;
  @override
  final double destinationLat;
  @override
  final double destinationLng;
  @override
  @JsonKey()
  final String status;
// en_attente, accepte, en_cours, termine, annule
  @override
  final String typeTrajet;
// immediat, programme, covoiturage
  @override
  final double? fare;
  @override
  final DateTime? scheduledAt;
  @override
  final String? driverId;

  @override
  String toString() {
    return 'Trip(id: $id, passengerId: $passengerId, pickupAddress: $pickupAddress, destinationAddress: $destinationAddress, destinationLat: $destinationLat, destinationLng: $destinationLng, status: $status, typeTrajet: $typeTrajet, fare: $fare, scheduledAt: $scheduledAt, driverId: $driverId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.passengerId, passengerId) ||
                other.passengerId == passengerId) &&
            (identical(other.pickupAddress, pickupAddress) ||
                other.pickupAddress == pickupAddress) &&
            (identical(other.destinationAddress, destinationAddress) ||
                other.destinationAddress == destinationAddress) &&
            (identical(other.destinationLat, destinationLat) ||
                other.destinationLat == destinationLat) &&
            (identical(other.destinationLng, destinationLng) ||
                other.destinationLng == destinationLng) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.typeTrajet, typeTrajet) ||
                other.typeTrajet == typeTrajet) &&
            (identical(other.fare, fare) || other.fare == fare) &&
            (identical(other.scheduledAt, scheduledAt) ||
                other.scheduledAt == scheduledAt) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      passengerId,
      pickupAddress,
      destinationAddress,
      destinationLat,
      destinationLng,
      status,
      typeTrajet,
      fare,
      scheduledAt,
      driverId);

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      __$$TripImplCopyWithImpl<_$TripImpl>(this, _$identity);
}

abstract class _Trip implements Trip {
  const factory _Trip(
      {required final String id,
      required final String passengerId,
      required final String pickupAddress,
      required final String destinationAddress,
      required final double destinationLat,
      required final double destinationLng,
      final String status,
      required final String typeTrajet,
      final double? fare,
      final DateTime? scheduledAt,
      final String? driverId}) = _$TripImpl;

  @override
  String get id;
  @override
  String get passengerId;
  @override
  String get pickupAddress;
  @override
  String get destinationAddress;
  @override
  double get destinationLat;
  @override
  double get destinationLng;
  @override
  String get status; // en_attente, accepte, en_cours, termine, annule
  @override
  String get typeTrajet; // immediat, programme, covoiturage
  @override
  double? get fare;
  @override
  DateTime? get scheduledAt;
  @override
  String? get driverId;

  /// Create a copy of Trip
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
