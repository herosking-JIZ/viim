import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/dio_interceptor.dart';
import 'screens/phone_input_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/setup_totp_screen.dart';
import 'screens/verify_totp_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dio client
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8000/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  // Initialize secure storage
  const secureStorage = FlutterSecureStorage();

  // Initialize auth service
  final authService = AuthService(
    dio: dio,
    secureStorage: secureStorage,
  );

  // Add interceptor for token refresh
  dio.interceptors.add(
    AuthInterceptor(
      authService: authService,
      onUnauthorized: (message) {
        // Redirect to login on unauthorized
        print('Unauthorized: $message');
      },
    ),
  );

  runApp(MyApp(authService: authService));
}

class MyApp extends StatefulWidget {
  final AuthService authService;

  const MyApp({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: '/login',
      routes: [
        // Login screen (phone input)
        GoRoute(
          path: '/login',
          builder: (context, state) => PhoneInputScreen(
            authService: widget.authService,
          ),
        ),

        // OTP verification screen
        GoRoute(
          path: '/otp-verify',
          builder: (context, state) {
            final args = state.extra as Map<String, String>;
            return OtpVerificationScreen(
              authService: widget.authService,
              phone: args['phone']!,
              phoneMasked: args['phone_masked']!,
            );
          },
        ),

        // TOTP setup screen (2FA registration)
        GoRoute(
          path: '/setup-totp',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return SetupTotpScreen(
              authService: widget.authService,
              loginToken: args['login_token']!,
              qrCodeUrl: args['qr_code_url']!,
              totpSecret: args['totp_secret']!,
            );
          },
        ),

        // TOTP verification screen (2FA login)
        GoRoute(
          path: '/verify-totp',
          builder: (context, state) {
            final args = state.extra as Map<String, String>;
            return VerifyTotpScreen(
              authService: widget.authService,
              loginToken: args['login_token']!,
            );
          },
        ),

        // Dashboard (after successful login)
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
      ],

      // Redirect to login if not authenticated
      redirect: (context, state) async {
        final isAuthenticated = await widget.authService.isAuthenticated();
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        if (isAuthenticated && isLoggingIn) {
          return '/dashboard';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>.value(
      value: widget.authService,
      child: MaterialApp.router(
        title: 'N\'DJIGI',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}

/// Placeholder dashboard screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        centerTitle: true,
      ),
      body: Center(
        child: Consumer<AuthService>(
          builder: (context, authService, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenue sur N\'DJIGI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await authService.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
