import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/routes.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/compte_suspendu_screen.dart';
import '../../features/auth/presentation/screens/keycloak_callback_screen.dart';
import '../../features/auth/presentation/screens/phone_collection_screen.dart';
import '../../features/home/presentation/screens/home_passager_screen.dart';
import '../../features/home/presentation/screens/home_chauffeur_screen.dart';
import '../../features/home/presentation/screens/home_proprietaire_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (previous, next) {
    authListenable.value = next;
  });
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authListenable,
    onException: (context, state, router) {
      if (state.uri.scheme == 'ndjigi-mobile') {
        // Deep link custom — app_links s'en occupe, GoRouter ignore
        return;
      }
      // Toute autre erreur de routing → splash
      router.go(Routes.splash);
    },
    redirect: (context, state) {
      // ✅ Ignorer les URLs avec scheme non-http dans le redirect
      final scheme = state.uri.scheme;
      if (scheme != 'http' && scheme != 'https' && scheme != '') {
        return null; // GoRouter ne touche pas à ces URLs
      }

      final authState = authListenable.value;

      final isSplash = state.matchedLocation == Routes.splash;
      final isAuth = [Routes.welcome, Routes.login, Routes.register].contains(state.matchedLocation);
      final isRoleSelection = state.matchedLocation == Routes.roleSelection;
      final isCompteSuspendu = state.matchedLocation == Routes.compteSuspendu;
      final isKeycloakCallback = state.matchedLocation == Routes.keycloakCallback;
      final isPhoneCollection = state.matchedLocation == Routes.phoneCollection;
      final isHome = state.matchedLocation.startsWith('/home/');

      if (authState.isLoading) {
        return isSplash ? null : Routes.splash;
      }

      if (authState.isAuthenticated && authState.user?.statutCompte == 'suspendu') {
        return isCompteSuspendu ? null : Routes.compteSuspendu;
      }

      if (authState.isAuthenticated) {
        if (isHome) return null;
        if (isAuth || isSplash) {
          return '/home/${authState.activeRole ?? "passager"}';
        }
        return null;
      }

      if (isAuth || isSplash || isRoleSelection || isKeycloakCallback || isPhoneCollection) {
        return null;
      }
      return Routes.splash;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.roleSelection,
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: Routes.compteSuspendu,
        name: 'compte-suspendu',
        builder: (context, state) => const CompteSuspendoScreen(),
      ),
      GoRoute(
        path: Routes.keycloakCallback,
        name: 'keycloak-callback',
        builder: (context, state) => KeycloakCallbackScreen(
          code: state.uri.queryParameters['code'],
          state: state.uri.queryParameters['state'],
          error: state.uri.queryParameters['error'],
        ),
      ),
      GoRoute(
        path: Routes.phoneCollection,
        name: 'phone-collection',
        builder: (context, state) => const PhoneCollectionScreen(),
      ),
      GoRoute(
        path: '/home/passager',
        name: 'home-passager',
        builder: (context, state) => const HomePassagerScreen(),
      ),
      GoRoute(
        path: '/home/chauffeur',
        name: 'home-chauffeur',
        builder: (context, state) => const HomeChauffeurScreen(),
      ),
      GoRoute(
        path: '/home/proprietaire',
        name: 'home-proprietaire',
        builder: (context, state) => const HomeProprietaireScreen(),
      ),
    ],
  );
});
