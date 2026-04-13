import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(name: 'id_utilisateur') required String id,
    required String email,
    required String nom,
    required String prenom,
    @JsonKey(name: 'photo_profil') String? photo,
    @Default([]) List<String> roles,
    String? accessToken,
    String? refreshToken,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  User toEntity() => User(
    id: id,
    email: email,
    firstName: prenom,
    lastName: nom,
    roles: roles,
    profilePictureUrl: photo,
  );
}