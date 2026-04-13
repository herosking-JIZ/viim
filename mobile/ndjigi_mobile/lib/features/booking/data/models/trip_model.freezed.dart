// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TripModel _$TripModelFromJson(Map<String, dynamic> json) {
  return _TripModel.fromJson(json);
}

/// @nodoc
mixin _$TripModel {
  @JsonKey(name: 'id_trajet')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'adresse_depart')
  String get pickupAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'adresse_arrivee')
  String get destinationAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'tarif_final')
  double? get fare => throw _privateConstructorUsedError;
  String get statut => throw _privateConstructorUsedError;
  @JsonKey(name: 'type_trajet')
  String get typeTrajet => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_utilisateur')
  String get passengerId =>
      throw _privateConstructorUsedError; // Coordonnées stockées en JSON dans ton schéma Prisma
  Map<String, dynamic>? get coordonnees_arrivee =>
      throw _privateConstructorUsedError;

  /// Serializes this TripModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TripModelCopyWith<TripModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripModelCopyWith<$Res> {
  factory $TripModelCopyWith(TripModel value, $Res Function(TripModel) then) =
      _$TripModelCopyWithImpl<$Res, TripModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id_trajet') String id,
      @JsonKey(name: 'adresse_depart') String pickupAddress,
      @JsonKey(name: 'adresse_arrivee') String destinationAddress,
      @JsonKey(name: 'tarif_final') double? fare,
      String statut,
      @JsonKey(name: 'type_trajet') String typeTrajet,
      @JsonKey(name: 'id_utilisateur') String passengerId,
      Map<String, dynamic>? coordonnees_arrivee});
}

/// @nodoc
class _$TripModelCopyWithImpl<$Res, $Val extends TripModel>
    implements $TripModelCopyWith<$Res> {
  _$TripModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pickupAddress = null,
    Object? destinationAddress = null,
    Object? fare = freezed,
    Object? statut = null,
    Object? typeTrajet = null,
    Object? passengerId = null,
    Object? coordonnees_arrivee = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      destinationAddress: null == destinationAddress
          ? _value.destinationAddress
          : destinationAddress // ignore: cast_nullable_to_non_nullable
              as String,
      fare: freezed == fare
          ? _value.fare
          : fare // ignore: cast_nullable_to_non_nullable
              as double?,
      statut: null == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as String,
      typeTrajet: null == typeTrajet
          ? _value.typeTrajet
          : typeTrajet // ignore: cast_nullable_to_non_nullable
              as String,
      passengerId: null == passengerId
          ? _value.passengerId
          : passengerId // ignore: cast_nullable_to_non_nullable
              as String,
      coordonnees_arrivee: freezed == coordonnees_arrivee
          ? _value.coordonnees_arrivee
          : coordonnees_arrivee // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripModelImplCopyWith<$Res>
    implements $TripModelCopyWith<$Res> {
  factory _$$TripModelImplCopyWith(
          _$TripModelImpl value, $Res Function(_$TripModelImpl) then) =
      __$$TripModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id_trajet') String id,
      @JsonKey(name: 'adresse_depart') String pickupAddress,
      @JsonKey(name: 'adresse_arrivee') String destinationAddress,
      @JsonKey(name: 'tarif_final') double? fare,
      String statut,
      @JsonKey(name: 'type_trajet') String typeTrajet,
      @JsonKey(name: 'id_utilisateur') String passengerId,
      Map<String, dynamic>? coordonnees_arrivee});
}

/// @nodoc
class __$$TripModelImplCopyWithImpl<$Res>
    extends _$TripModelCopyWithImpl<$Res, _$TripModelImpl>
    implements _$$TripModelImplCopyWith<$Res> {
  __$$TripModelImplCopyWithImpl(
      _$TripModelImpl _value, $Res Function(_$TripModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pickupAddress = null,
    Object? destinationAddress = null,
    Object? fare = freezed,
    Object? statut = null,
    Object? typeTrajet = null,
    Object? passengerId = null,
    Object? coordonnees_arrivee = freezed,
  }) {
    return _then(_$TripModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      destinationAddress: null == destinationAddress
          ? _value.destinationAddress
          : destinationAddress // ignore: cast_nullable_to_non_nullable
              as String,
      fare: freezed == fare
          ? _value.fare
          : fare // ignore: cast_nullable_to_non_nullable
              as double?,
      statut: null == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as String,
      typeTrajet: null == typeTrajet
          ? _value.typeTrajet
          : typeTrajet // ignore: cast_nullable_to_non_nullable
              as String,
      passengerId: null == passengerId
          ? _value.passengerId
          : passengerId // ignore: cast_nullable_to_non_nullable
              as String,
      coordonnees_arrivee: freezed == coordonnees_arrivee
          ? _value._coordonnees_arrivee
          : coordonnees_arrivee // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripModelImpl implements _TripModel {
  const _$TripModelImpl(
      {@JsonKey(name: 'id_trajet') required this.id,
      @JsonKey(name: 'adresse_depart') required this.pickupAddress,
      @JsonKey(name: 'adresse_arrivee') required this.destinationAddress,
      @JsonKey(name: 'tarif_final') this.fare,
      required this.statut,
      @JsonKey(name: 'type_trajet') required this.typeTrajet,
      @JsonKey(name: 'id_utilisateur') required this.passengerId,
      final Map<String, dynamic>? coordonnees_arrivee})
      : _coordonnees_arrivee = coordonnees_arrivee;

  factory _$TripModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripModelImplFromJson(json);

  @override
  @JsonKey(name: 'id_trajet')
  final String id;
  @override
  @JsonKey(name: 'adresse_depart')
  final String pickupAddress;
  @override
  @JsonKey(name: 'adresse_arrivee')
  final String destinationAddress;
  @override
  @JsonKey(name: 'tarif_final')
  final double? fare;
  @override
  final String statut;
  @override
  @JsonKey(name: 'type_trajet')
  final String typeTrajet;
  @override
  @JsonKey(name: 'id_utilisateur')
  final String passengerId;
// Coordonnées stockées en JSON dans ton schéma Prisma
  final Map<String, dynamic>? _coordonnees_arrivee;
// Coordonnées stockées en JSON dans ton schéma Prisma
  @override
  Map<String, dynamic>? get coordonnees_arrivee {
    final value = _coordonnees_arrivee;
    if (value == null) return null;
    if (_coordonnees_arrivee is EqualUnmodifiableMapView)
      return _coordonnees_arrivee;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'TripModel(id: $id, pickupAddress: $pickupAddress, destinationAddress: $destinationAddress, fare: $fare, statut: $statut, typeTrajet: $typeTrajet, passengerId: $passengerId, coordonnees_arrivee: $coordonnees_arrivee)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pickupAddress, pickupAddress) ||
                other.pickupAddress == pickupAddress) &&
            (identical(other.destinationAddress, destinationAddress) ||
                other.destinationAddress == destinationAddress) &&
            (identical(other.fare, fare) || other.fare == fare) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.typeTrajet, typeTrajet) ||
                other.typeTrajet == typeTrajet) &&
            (identical(other.passengerId, passengerId) ||
                other.passengerId == passengerId) &&
            const DeepCollectionEquality()
                .equals(other._coordonnees_arrivee, _coordonnees_arrivee));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      pickupAddress,
      destinationAddress,
      fare,
      statut,
      typeTrajet,
      passengerId,
      const DeepCollectionEquality().hash(_coordonnees_arrivee));

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TripModelImplCopyWith<_$TripModelImpl> get copyWith =>
      __$$TripModelImplCopyWithImpl<_$TripModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripModelImplToJson(
      this,
    );
  }
}

abstract class _TripModel implements TripModel {
  const factory _TripModel(
      {@JsonKey(name: 'id_trajet') required final String id,
      @JsonKey(name: 'adresse_depart') required final String pickupAddress,
      @JsonKey(name: 'adresse_arrivee')
      required final String destinationAddress,
      @JsonKey(name: 'tarif_final') final double? fare,
      required final String statut,
      @JsonKey(name: 'type_trajet') required final String typeTrajet,
      @JsonKey(name: 'id_utilisateur') required final String passengerId,
      final Map<String, dynamic>? coordonnees_arrivee}) = _$TripModelImpl;

  factory _TripModel.fromJson(Map<String, dynamic> json) =
      _$TripModelImpl.fromJson;

  @override
  @JsonKey(name: 'id_trajet')
  String get id;
  @override
  @JsonKey(name: 'adresse_depart')
  String get pickupAddress;
  @override
  @JsonKey(name: 'adresse_arrivee')
  String get destinationAddress;
  @override
  @JsonKey(name: 'tarif_final')
  double? get fare;
  @override
  String get statut;
  @override
  @JsonKey(name: 'type_trajet')
  String get typeTrajet;
  @override
  @JsonKey(name: 'id_utilisateur')
  String get passengerId; // Coordonnées stockées en JSON dans ton schéma Prisma
  @override
  Map<String, dynamic>? get coordonnees_arrivee;

  /// Create a copy of TripModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TripModelImplCopyWith<_$TripModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
