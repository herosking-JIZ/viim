import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<ApiResponse<UserModel>> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<ApiResponse<UserModel>> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'mot_de_passe': password, // Nom de champ du contrat
    });

    return ApiResponse.fromJson(
      response.data,
          (json) => UserModel.fromJson(json),
    );
  }
}