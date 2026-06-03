// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'utilisateur.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Utilisateur _$UtilisateurFromJson(Map<String, dynamic> json) {
  return _Utilisateur.fromJson(json);
}

/// @nodoc
mixin _$Utilisateur {
  String get id => throw _privateConstructorUsedError;
  String get nom => throw _privateConstructorUsedError;
  String get prenom => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get telephone => throw _privateConstructorUsedError;
  List<UtilisateurRole> get roles => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get adresse => throw _privateConstructorUsedError;
  String? get dateNaissance => throw _privateConstructorUsedError;
  bool? get estVerifie => throw _privateConstructorUsedError;
  bool? get estActif => throw _privateConstructorUsedError;
  DateTime? get dateCreation => throw _privateConstructorUsedError;
  DateTime? get dateModification => throw _privateConstructorUsedError;

  /// Serializes this Utilisateur to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Utilisateur
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UtilisateurCopyWith<Utilisateur> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UtilisateurCopyWith<$Res> {
  factory $UtilisateurCopyWith(
    Utilisateur value,
    $Res Function(Utilisateur) then,
  ) = _$UtilisateurCopyWithImpl<$Res, Utilisateur>;
  @useResult
  $Res call({
    String id,
    String nom,
    String prenom,
    String email,
    String telephone,
    List<UtilisateurRole> roles,
    String? photoUrl,
    String? adresse,
    String? dateNaissance,
    bool? estVerifie,
    bool? estActif,
    DateTime? dateCreation,
    DateTime? dateModification,
  });
}

/// @nodoc
class _$UtilisateurCopyWithImpl<$Res, $Val extends Utilisateur>
    implements $UtilisateurCopyWith<$Res> {
  _$UtilisateurCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Utilisateur
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nom = null,
    Object? prenom = null,
    Object? email = null,
    Object? telephone = null,
    Object? roles = null,
    Object? photoUrl = freezed,
    Object? adresse = freezed,
    Object? dateNaissance = freezed,
    Object? estVerifie = freezed,
    Object? estActif = freezed,
    Object? dateCreation = freezed,
    Object? dateModification = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            nom: null == nom
                ? _value.nom
                : nom // ignore: cast_nullable_to_non_nullable
                      as String,
            prenom: null == prenom
                ? _value.prenom
                : prenom // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            telephone: null == telephone
                ? _value.telephone
                : telephone // ignore: cast_nullable_to_non_nullable
                      as String,
            roles: null == roles
                ? _value.roles
                : roles // ignore: cast_nullable_to_non_nullable
                      as List<UtilisateurRole>,
            photoUrl: freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            adresse: freezed == adresse
                ? _value.adresse
                : adresse // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateNaissance: freezed == dateNaissance
                ? _value.dateNaissance
                : dateNaissance // ignore: cast_nullable_to_non_nullable
                      as String?,
            estVerifie: freezed == estVerifie
                ? _value.estVerifie
                : estVerifie // ignore: cast_nullable_to_non_nullable
                      as bool?,
            estActif: freezed == estActif
                ? _value.estActif
                : estActif // ignore: cast_nullable_to_non_nullable
                      as bool?,
            dateCreation: freezed == dateCreation
                ? _value.dateCreation
                : dateCreation // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            dateModification: freezed == dateModification
                ? _value.dateModification
                : dateModification // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UtilisateurImplCopyWith<$Res>
    implements $UtilisateurCopyWith<$Res> {
  factory _$$UtilisateurImplCopyWith(
    _$UtilisateurImpl value,
    $Res Function(_$UtilisateurImpl) then,
  ) = __$$UtilisateurImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String nom,
    String prenom,
    String email,
    String telephone,
    List<UtilisateurRole> roles,
    String? photoUrl,
    String? adresse,
    String? dateNaissance,
    bool? estVerifie,
    bool? estActif,
    DateTime? dateCreation,
    DateTime? dateModification,
  });
}

/// @nodoc
class __$$UtilisateurImplCopyWithImpl<$Res>
    extends _$UtilisateurCopyWithImpl<$Res, _$UtilisateurImpl>
    implements _$$UtilisateurImplCopyWith<$Res> {
  __$$UtilisateurImplCopyWithImpl(
    _$UtilisateurImpl _value,
    $Res Function(_$UtilisateurImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Utilisateur
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nom = null,
    Object? prenom = null,
    Object? email = null,
    Object? telephone = null,
    Object? roles = null,
    Object? photoUrl = freezed,
    Object? adresse = freezed,
    Object? dateNaissance = freezed,
    Object? estVerifie = freezed,
    Object? estActif = freezed,
    Object? dateCreation = freezed,
    Object? dateModification = freezed,
  }) {
    return _then(
      _$UtilisateurImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nom: null == nom
            ? _value.nom
            : nom // ignore: cast_nullable_to_non_nullable
                  as String,
        prenom: null == prenom
            ? _value.prenom
            : prenom // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        telephone: null == telephone
            ? _value.telephone
            : telephone // ignore: cast_nullable_to_non_nullable
                  as String,
        roles: null == roles
            ? _value._roles
            : roles // ignore: cast_nullable_to_non_nullable
                  as List<UtilisateurRole>,
        photoUrl: freezed == photoUrl
            ? _value.photoUrl
            : photoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        adresse: freezed == adresse
            ? _value.adresse
            : adresse // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateNaissance: freezed == dateNaissance
            ? _value.dateNaissance
            : dateNaissance // ignore: cast_nullable_to_non_nullable
                  as String?,
        estVerifie: freezed == estVerifie
            ? _value.estVerifie
            : estVerifie // ignore: cast_nullable_to_non_nullable
                  as bool?,
        estActif: freezed == estActif
            ? _value.estActif
            : estActif // ignore: cast_nullable_to_non_nullable
                  as bool?,
        dateCreation: freezed == dateCreation
            ? _value.dateCreation
            : dateCreation // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        dateModification: freezed == dateModification
            ? _value.dateModification
            : dateModification // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UtilisateurImpl implements _Utilisateur {
  const _$UtilisateurImpl({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required final List<UtilisateurRole> roles,
    this.photoUrl,
    this.adresse,
    this.dateNaissance,
    this.estVerifie,
    this.estActif,
    this.dateCreation,
    this.dateModification,
  }) : _roles = roles;

  factory _$UtilisateurImpl.fromJson(Map<String, dynamic> json) =>
      _$$UtilisateurImplFromJson(json);

  @override
  final String id;
  @override
  final String nom;
  @override
  final String prenom;
  @override
  final String email;
  @override
  final String telephone;
  final List<UtilisateurRole> _roles;
  @override
  List<UtilisateurRole> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  final String? photoUrl;
  @override
  final String? adresse;
  @override
  final String? dateNaissance;
  @override
  final bool? estVerifie;
  @override
  final bool? estActif;
  @override
  final DateTime? dateCreation;
  @override
  final DateTime? dateModification;

  @override
  String toString() {
    return 'Utilisateur(id: $id, nom: $nom, prenom: $prenom, email: $email, telephone: $telephone, roles: $roles, photoUrl: $photoUrl, adresse: $adresse, dateNaissance: $dateNaissance, estVerifie: $estVerifie, estActif: $estActif, dateCreation: $dateCreation, dateModification: $dateModification)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UtilisateurImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nom, nom) || other.nom == nom) &&
            (identical(other.prenom, prenom) || other.prenom == prenom) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.telephone, telephone) ||
                other.telephone == telephone) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.adresse, adresse) || other.adresse == adresse) &&
            (identical(other.dateNaissance, dateNaissance) ||
                other.dateNaissance == dateNaissance) &&
            (identical(other.estVerifie, estVerifie) ||
                other.estVerifie == estVerifie) &&
            (identical(other.estActif, estActif) ||
                other.estActif == estActif) &&
            (identical(other.dateCreation, dateCreation) ||
                other.dateCreation == dateCreation) &&
            (identical(other.dateModification, dateModification) ||
                other.dateModification == dateModification));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nom,
    prenom,
    email,
    telephone,
    const DeepCollectionEquality().hash(_roles),
    photoUrl,
    adresse,
    dateNaissance,
    estVerifie,
    estActif,
    dateCreation,
    dateModification,
  );

  /// Create a copy of Utilisateur
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UtilisateurImplCopyWith<_$UtilisateurImpl> get copyWith =>
      __$$UtilisateurImplCopyWithImpl<_$UtilisateurImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UtilisateurImplToJson(this);
  }
}

abstract class _Utilisateur implements Utilisateur {
  const factory _Utilisateur({
    required final String id,
    required final String nom,
    required final String prenom,
    required final String email,
    required final String telephone,
    required final List<UtilisateurRole> roles,
    final String? photoUrl,
    final String? adresse,
    final String? dateNaissance,
    final bool? estVerifie,
    final bool? estActif,
    final DateTime? dateCreation,
    final DateTime? dateModification,
  }) = _$UtilisateurImpl;

  factory _Utilisateur.fromJson(Map<String, dynamic> json) =
      _$UtilisateurImpl.fromJson;

  @override
  String get id;
  @override
  String get nom;
  @override
  String get prenom;
  @override
  String get email;
  @override
  String get telephone;
  @override
  List<UtilisateurRole> get roles;
  @override
  String? get photoUrl;
  @override
  String? get adresse;
  @override
  String? get dateNaissance;
  @override
  bool? get estVerifie;
  @override
  bool? get estActif;
  @override
  DateTime? get dateCreation;
  @override
  DateTime? get dateModification;

  /// Create a copy of Utilisateur
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UtilisateurImplCopyWith<_$UtilisateurImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
