import 'package:freezed_annotation/freezed_annotation.dart';
import 'utilisateur_role.dart';

part 'utilisateur.freezed.dart';
part 'utilisateur.g.dart';

@freezed
class Utilisateur with _$Utilisateur {
  const factory Utilisateur({
    required String id,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required List<UtilisateurRole> roles,
    String? photoUrl,
    String? adresse,
    String? dateNaissance,
    bool? estVerifie,
    bool? estActif,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) = _Utilisateur;

  factory Utilisateur.fromJson(Map<String, dynamic> json) => _$UtilisateurFromJson(json);
}
