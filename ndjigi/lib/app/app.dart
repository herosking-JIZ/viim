import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'N\'DJIGI',
      debugShowCheckedModeBanner: AppConfig.isDebug,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: const Locale('fr', 'BF'),
      supportedLocales: const [
        Locale('fr', 'BF'),
        Locale('en', 'US'),
      ],
      routerConfig: AppRouter.router,
    );
  }
}
