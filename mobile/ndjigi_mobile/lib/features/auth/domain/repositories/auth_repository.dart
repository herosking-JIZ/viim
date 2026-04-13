import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';

// État de l'auth
class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.user, this.isLoading = false, this.errorMessage});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;

  AuthNotifier(this.loginUseCase) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true);
    final result = await loginUseCase.execute(email, password);

    result.fold(
          (failure) => state = AuthState(errorMessage: failure.message),
          (user) => state = AuthState(user: user),
    );
  }
}

// Les providers (À injecter dans main.dart ou via un fichier d'injection)