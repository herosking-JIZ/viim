import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../domain/entities/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  AuthState({this.user, this.isLoading = false, this.errorMessage});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true);

    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase.execute(email, password);

    result.fold(
          (failure) => state = AuthState(errorMessage: failure.message),
          (user) {
        // Logique de redirection ou stockage ici
        state = AuthState(user: user);
      },
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});