// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'utilisateur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UtilisateurImpl _$$UtilisateurImplFromJson(Map<String, dynamic> json) =>
    _$UtilisateurImpl(
      id: json['id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String,
      roles: (json['roles'] as List<dynamic>)
          .map((e) => $enumDecode(_$UtilisateurRoleEnumMap, e))
          .toList(),
      photoUrl: json['photoUrl'] as String?,
      adresse: json['adresse'] as String?,
      dateNaissance: json['dateNaissance'] as String?,
      estVerifie: json['estVerifie'] as bool?,
      estActif: json['estActif'] as bool?,
      dateCreation: json['dateCreation'] == null
          ? null
          : DateTime.parse(json['dateCreation'] as String),
      dateModification: json['dateModification'] == null
          ? null
          : DateTime.parse(json['dateModification'] as String),
    );

Map<String, dynamic> _$$UtilisateurImplToJson(_$UtilisateurImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'email': instance.email,
      'telephone': instance.telephone,
      'roles': instance.roles.map((e) => _$UtilisateurRoleEnumMap[e]!).toList(),
      'photoUrl': instance.photoUrl,
      'adresse': instance.adresse,
      'dateNaissance': instance.dateNaissance,
      'estVerifie': instance.estVerifie,
      'estActif': instance.estActif,
      'dateCreation': instance.dateCreation?.toIso8601String(),
      'dateModification': instance.dateModification?.toIso8601String(),
    };

const _$UtilisateurRoleEnumMap = {
  UtilisateurRole.passager: 'passager',
  UtilisateurRole.chauffeur: 'chauffeur',
  UtilisateurRole.proprietaire: 'proprietaire',
};
