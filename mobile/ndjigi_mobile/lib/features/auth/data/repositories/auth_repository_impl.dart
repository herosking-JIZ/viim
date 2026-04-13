// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User>> login(String identifier, String password) async {
    try {
      final userModel = await remoteDataSource.login(identifier, password);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  // Les autres méthodes (register, uploadDocument) suivront la même logique
  @override
  Future<Either<Failure, User>> getCurrentUser() => throw UnimplementedError();
  @override
  Future<Either<Failure, void>> logout() => throw UnimplementedError();
  @override
  Future<Either<Failure, User>> register({required String phoneNumber, required String email, required String firstName, required String lastName, required String password}) => throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> uploadDocument({required String userId, required String type, required String filePath}) => throw UnimplementedError();
}